# pimatic-snmp

[![npm version](https://badge.fury.io/js/pimatic-snmp.svg)](http://badge.fury.io/js/pimatic-snmp)
[![dependencies status](https://david-dm.org/thost96/pimatic-snmp/status.svg)](https://david-dm.org/thost96/pimatic-snmp)
[![Build Status](https://travis-ci.org/thost96/pimatic-snmp.svg?branch=master)](https://travis-ci.org/thost96/pimatic-snmp)

A pimatic plugin to make snmp get request. The Oid can be found in the device mib file provided by the manufacture or using [Oidview](http://www.oidview.com/).

## Plugin Configuration

  {
          "plugin": "snmp"
    }

The plugin has the following configuration properties:

| Property          | Default  | Type    | Description                                 |
|:------------------|:---------|:--------|:--------------------------------------------|
| debug             | false    | Boolean | Debug mode. Writes debug messages to the pimatic log, if set to true|


## Device Configuration
The plugin supports auto discover of snmp devices on your connected networks.
As default the community `"public"` and the oid `'.1.3.6.1.2.1.1.5.0'` for sysname property are used.

The oids must be provied using this format: .x.xx.x.x.x.xxx - for example: .1.2.840.10006.300.43.1.3.0

The following device can also be created manually:

### SnmpSensor
The SnmpSensor displays the output of your specified command to the gui.

  {
      "id": "snmp1",
      "class": "SnmpSensor",
      "name": "Snmp Sensor",
      "host": "",
      "oids": [
        {
          "label": "SysName",
              "oid": ".1.3.6.1.2.1.1.5.0"
        }
      ]
  }

| Property          | Default  | Type    | Description                                 |
|:------------------|:---------|:--------|:--------------------------------------------|
| host              | -        | String  | Hostname or IP address of target device |
| port         | 161     | Number   | Port used by snmp
| oids         | -      | Array   | An array of oid objects.See device configuration schema for details |
| community      | "public" | String  | snmp community for read and/or write access  |
| interval       | 60000    | Number  | The time interval in milliseconds at which the oid is queried |
| attributes    | -       | Object  | Attributes are automatical saved to config for later support for rules |

If you already created a SnmpSensor device and you change the oids later, all attributes from this device need to be deleted manually, before the new attributes are shown.

### SnmpPresenceSensor
The SnmpSensor displays the output of your specified command to the gui.

  {
      "id": "snmp2",
      "class": "SnmpPresenceSensor",
      "name": "Snmp Presence Sensor",
      "host": "",
      "oids": [
        {
          "label": "State",
              "oid": ".1.3.6.1.2.1.1.5.0"
        }
      ]
  }

| Property          | Default  | Type    | Description                                 |
|:------------------|:---------|:--------|:--------------------------------------------|
| host              | -        | String  | Hostname or IP address of target device |
| port         | 161     | Number   | Port used by snmp
| oids         | -      | Array   | An array of oid objects. Only one object is supported! |
| community      | "public" | String  | snmp community for read and/or write access  |
| interval       | 60000    | Number  | The time interval in milliseconds at which the oid is queried |

Only one oid object is supported at the moment!

## ToDo

* Add automatic clearing of attributes if oids were changed
* Add set funtion for rule usage
* Add support for multiple presence sensors in one device

## History

See [Release History](https://github.com/thost96/pimatic-snmp/blob/master/History.md).

## License

Copyright (c) thost96 and contributors. All rights reserved.

License: [GPL-2.0](https://github.com/thost96/pimatic-snmp/blob/master/LICENSE).