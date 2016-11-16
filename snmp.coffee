capitalizeFirstLetter = (string) =>
  return string.charAt(0).toUpperCase() + string.slice(1)

module.exports = (env) ->

  Promise = env.require 'bluebird'
  snmp = require 'snmp-native'
  _ = env.require 'lodash'
  os = require 'os'
  ping = env.ping or require("net-ping")
 
  
  class SNMP extends env.plugins.Plugin

    init: (app, @framework, @config) =>

      @debug = @config.debug
      
      deviceConfigDef = require("./device-config-schema.coffee")      
      @framework.deviceManager.registerDeviceClass("SnmpSensor", {
        configDef: deviceConfigDef.SnmpSensor,
        createCallback: (config) => new SnmpSensor(config, @, @framework)
      })

      @framework.deviceManager.on 'discover', (eventData) =>
        @framework.deviceManager.discoverMessage 'pimatic-snmp', "scanning network for snmp devices"
        
        interfaces = @listInterfaces()
        maxPings = 513 #only /24 netmask
        pingCount = 0
        interfaces.forEach( (iface, ifNum) =>
          #/24 netmask only           
          base = iface.address.match(/([0-9]+\.[0-9]+\.[0-9]+\.)[0-9]+/)[1]
          @framework.deviceManager.discoverMessage 'pimatic-snmp', "Scanning #{base}0/#{iface.netmask}"
          
          #console.log base
          i = 1 #only /24 netmask

          while i < 256 #only netmask /24
            do (i) =>
              if pingCount > maxPings then return
              
              address = "#{base}#{i}" #increment ip base + i = x.x.x.i = 192.168.1.1/2/3/4
              sessionId = ((process.pid + i) % 65535)
              
              session = ping.createSession(
                networkProtocol: ping.NetworkProtocol.IPv4 #ipv4 only ?
                packetSize: 16
                retries: 1
                sessionId: sessionId
                timeout: eventData.time
                ttl: 128
              )
              session.pingHost(address, (error, target) =>
                session.close()
                unless error
                  snmpsession = Promise.promisifyAll( new snmp.Session({host: target, port: 161, community: "public"}) )       
                  snmpsession.getAsync({ oid: '.1.3.6.1.2.1.1.5.0' }).then( (result) =>
                    if not _.isEmpty(result)
                      
                      deviceConfig = 
                        id: "snmp-" + target.replace(/\./g,'') #or using sysname result[0].value?
                        name: result[0].value
                        class: 'SnmpSensor'
                        oid: '.1.3.6.1.2.1.1.5.0'
                        host: target

                      @framework.deviceManager.discoveredDevice 'pimatic-snmp', "#{deviceConfig.name}", deviceConfig
                  ).catch ( (err) ->
                    return 
                  )                            
              )

            i++
            pingCount++

          if pingCount > maxPings
            @framework.deviceManager.discoverMessage 'pimatic-snmp', "Could not ping all networks, max ping cound reached."
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
      @debug = @plugin.config.debug 
      @timers = []
      @community = @config.community
      @oid = @config.oid

      @session = new snmp.Session({host: @config.host, port: @config.port, community: "#{@community}"})        
      Promise.promisifyAll @session      
      if @debug
        env.logger.debug @session 

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
            #fix for directly reading data from device
            @readSnmpData()
            @['get' + (capitalizeFirstLetter attrName)]()
            #schedule function for reading data from device using interval
            @timers.push setInterval(
              ( =>
                @readSnmpData()
                @['get' + (capitalizeFirstLetter attrName)]()
              ), @config.interval
            )    
      else
        @session.getAsync({ oid: @oid }).then( (result) =>
          if result.length > 0
            if @debug
              env.logger.debug JSON.stringify(result) 
            
            @attr = _.cloneDeep(@attributes)
            for own value of result
              type = null
              if _.isNumber(value)
                type = "number"
              else if _.isBoolean(value)
                type = "boolean"
              else
                type = "string"

              @attr[@config.oid.toString()] = {
                type: type
                description: @config.oid.toString()
                value: value
                acronym: @config.oid.toString()
              }
            if @debug
              env.logger.debug @attr

            @config.attributes = @attr
            @framework.deviceManager.recreateDevice(@, @config)
          else
            env.logger.error "empty result for wmi query #{@command}"
        )      
      super(@config, @plugin, @framework)  

    destroy: () ->
      for timerId in @timers
        clearInterval timerId
      super()

    readSnmpData: () ->
      @session.getAsync({ oid: @oid }).then( (result) =>
        if @debug
          env.logger.debug result[0].oid + ' : ' + result[0].value 
        if @config.attributes[@config.oid.toString()].value isnt result[0].value or not @config.attributes[@config.oid.toString()].discrete
          @emit @config.oid.toString(), result[0].value
        @attributes[@config.oid.toString()].value = result[0].value
        @config.attributes[@config.oid.toString()].value = result[0].value
        Promise.resolve @attributes[@config.oid.toString()].value
      )

  return new SNMP