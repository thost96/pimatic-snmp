module.exports = {
  title: "pimatic-snmp device config options"
  SnmpSensor:
    title: "SnmpSensor config options"
    type: "object"
    properties:
      host:
        description: "host dns name or ip address"
        type: "string"
      port:
        description: "port used for snmp"
        type: "number"
        default: 161
      oids:
        description: "device specific oids"
        type: "array"
        format: "table"
        default: []
        items:
          type: "object"
          properties:
            label:
              type: "string"
              description: "oid label"
            oid:        
              type: "string"
              description: "device specific oid"
      community:
        description: "snmp comunity name"
        type: "string"
        default: "public"
      interval:
        description: "interval"
        type: "number"
        default: 60000
      attributes:
        description: "attributes"
        type: "object"
  SnmpPresenceSensor: 
    title: "SnmpPresenceSensor config options"
    type: "object"
    properties:
      host:
        description: "host dns name or ip address"
        type: "string"
      port:
        description: "port used for snmp"
        type: "number"
        default: 161
      oids:
        description: "device specific oids"
        type: "array"
        format: "table"
        default: []
        items:
          type: "object"
          properties:
            label:
              type: "string"
              description: "oid label"
            oid:        
              type: "string"
              description: "device specific oid"
      community:
        description: "snmp comunity name"
        type: "string"
        default: "public"
      interval:
        description: "interval"
        type: "number"
        default: 60000
}