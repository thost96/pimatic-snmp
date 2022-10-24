capitalizeFirstLetter = (string) =>
  return string.charAt(0).toUpperCase() + string.slice(1)

module.exports = (env) ->

  Promise = env.require 'bluebird'
  snmp = require 'snmp-native'
  _ = env.require 'lodash'
  os = require 'os'
  Netmask = require('netmask').Netmask

    
  class SNMP extends env.plugins.Plugin

    init: (app, @framework, @config) =>

      @debug = @config.debug
      
      deviceConfigDef = require("./device-config-schema.coffee")      
      @framework.deviceManager.registerDeviceClass("SnmpSensor", {
        configDef: deviceConfigDef.SnmpSensor,
        createCallback: (config) => new SnmpSensor(config, @, @framework)
      })
      @framework.deviceManager.registerDeviceClass("SnmpPresenceSensor", {
        configDef: deviceConfigDef.SnmpPresenceSensor,
        createCallback: (config, lastState) => new SnmpPresenceSensor(config, @, @framework, lastState)
      })


      @framework.deviceManager.on 'discover', (eventData) =>
        @framework.deviceManager.discoverMessage 'pimatic-snmp', "scanning network for snmp devices"
        
        interfaces = @listInterfaces()
        interfaces.forEach( (iface) =>

          @framework.deviceManager.discoverMessage 'pimatic-snmp', "Scanning #{iface.address}/#{iface.netmask}"
         
          block = new Netmask("#{iface.address}/#{iface.netmask}")
          block.forEach( (ip, long, index) =>  

            snmpsession = Promise.promisifyAll( new snmp.Session({host: ip, port: 161, community: "public"}) ) 
            snmpsession.getAsync({ oid: '.1.3.6.1.2.1.1.5.0' }).then( (result) =>
              if not _.isEmpty(result)

                deviceConfig = 
                  id: "snmp-" + ip.replace(/\./g,'') 
                  name: result[0].value
                  class: 'SnmpSensor'
                  oids: [{
                    label: "SysName"
                    oid: '.1.3.6.1.2.1.1.5.0'
                  }]
                  host: ip

                @framework.deviceManager.discoveredDevice 'pimatic-snmp', "#{deviceConfig.name}", deviceConfig
            ).catch ( (err) ->
              return 
            )  
          )
        )

    listInterfaces: () ->
      interfaces = []
      ifaces = os.networkInterfaces()
      Object.keys(ifaces).forEach( (ifname) =>
        ifaces[ifname].forEach (iface) =>
          # skip over internal (i.e. 127.0.0.1) and non-ipv4 addresses
          if 'IPv4' isnt iface.family or iface.internal isnt false then return
          if @debug
            env.logger.debug iface
          interfaces.push {name: ifname, address: iface.address, netmask: iface.netmask}
      )
      return interfaces


  class SnmpSensor extends env.devices.Sensor

    constructor: (@config, @plugin, @framework) ->
      @id = @config.id
      @name = @config.name  
      @debug = @plugin.debug 
      @community = @config.community
      @oids = @config.oids
      @timers = []
      @ids = []
      @labels = []

      for oid in @oids
        @ids.push oid.oid  
        @labels.push oid.label     

      @session = new snmp.Session({host: @config.host, port: @config.port, community: "#{@community}"})        
      Promise.promisifyAll @session      
      if @debug
        env.logger.debug @session.options

      if not _.isEmpty(@config.attributes)
        @attributes = @config.attributes
        for own attrName of @config.attributes
          do (attrName) =>
            @_createGetter(attrName, () =>
              if @attributes[attrName]?
                if @attributes[attrName].value?
                  Promise.resolve @attributes[attrName].value
                else
                  Promise.reject "Invalid value for attribute: #{attrName}"
              else
                Promise.reject "No such attribute: #{attrName}"
            )
            @readSnmpData()
            @['get' + (capitalizeFirstLetter attrName)]()
            @timers.push setInterval(
              ( =>
                @readSnmpData()
                @['get' + (capitalizeFirstLetter attrName)]()
              ), @config.interval
            )    
      else
        @session.getAllAsync({ oids: @ids }).then( (varbinds) =>
          if varbinds.length > 0
            if @debug
              env.logger.debug JSON.stringify(varbinds) 
            @attr = _.cloneDeep(@attributes)

            for key, val of varbinds   
              type = null
              if _.isNumber(val.value)
                type = "number"
              else if _.isBoolean(val.value)
                type = "boolean"
              else
                type = "string"

              @attr[@labels[key]] = {
                  type: type
                  description: @labels[key]
                  value: val.value
                  acronym: @labels[key]
                }
              if @debug
                env.logger.debug @attr

              @config.attributes = @attr
              @framework.deviceManager.recreateDevice(@, @config)              
          else
            env.logger.error "empty result for snmp query #{@ids}"
        )      
      super(@config, @plugin, @framework)  

    destroy: () ->
      for timerId in @timers
        clearInterval timerId
      super()

    readSnmpData: () ->
      @session.getAllAsync({ oids: @ids }).then( (varbinds) =>
        if varbinds.length > 0
          if @debug
            env.logger.debug JSON.stringify(varbinds) 

          for key, val of varbinds
            if @config.attributes[@labels[key]].value isnt val.value or not @config.attributes[@labels[key]].discrete
              @emit @labels[key], val.value
            @attributes[@labels[key]].value = val.value
            @config.attributes[@labels[key]].value = val.value
            Promise.resolve @attributes[@labels[key]].value
        else 
          if @debug
            env.logger.debug "empty result for snmp query #{@ids}" 
      )


  class SnmpPresenceSensor extends env.devices.PresenceSensor

    constructor: (@config, @plugin, @framework, lastState) ->
      @id = @config.id
      @name = @config.name  
      @debug = @plugin.debug 
      @community = @config.community
      @oids = @config.oids
      @timers = []
      @ids = []
      @_presence = lastState?.presence?.value or false

      for oid in @oids
        @ids.push oid.oid    

      @session = new snmp.Session({host: @config.host, port: @config.port, community: "#{@community}"})        
      Promise.promisifyAll @session      
      if @debug
        env.logger.debug @session.options     

      @readSnmpData()
      @timers.push setInterval(
        ( =>
          @readSnmpData()
        ), @config.interval
      ) 
      super(@config, @plugin, @framework, lastState)  

    destroy: () ->
      for timerId in @timers
        clearInterval timerId
      super()

    readSnmpData: () =>
      @session.getAllAsync({ oids: @ids }).then( (varbinds) =>
        if varbinds.length > 0
          if @debug
            env.logger.debug JSON.stringify(varbinds) 

          if varbinds.length > 1
            env.logger.warn "Only one oid is supported"

          if varbinds[0].value is 1 
            @_setPresence yes
            @getPresence()
          else
            @_setPresence no
            @getPresence()
    
        else 
          if @debug
            env.logger.debug "empty result for snmp query #{@ids}" 
      )

    getPresence: () ->
      if @debug
        env.logger.debug @_presence
      Promise.resolve(@_presence) 

  return new SNMP