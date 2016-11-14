capitalizeFirstLetter = (string) =>
  return string.charAt(0).toUpperCase() + string.slice(1)

module.exports = (env) ->

  Promise = env.require 'bluebird'
  snmp = require 'snmp-native'
  _ = env.require 'lodash'
  
  class SNMP extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      
      deviceConfigDef = require("./device-config-schema.coffee")
      
      @framework.deviceManager.registerDeviceClass("SnmpSensor", {
        configDef: deviceConfigDef.SnmpSensor,
        createCallback: (config) => new SnmpSensor(config, @, @framework)
      })
      

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