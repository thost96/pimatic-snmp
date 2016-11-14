# pimatic-snmp

[![npm version](https://badge.fury.io/js/pimatic-snmp.svg)](http://badge.fury.io/js/pimatic-snmp)
[![dependencies status](https://david-dm.org/thost96/pimatic-snmp/status.svg)](https://david-dm.org/thost96/pimatic-snmp)

A pimatic plugin to make snmp get request. The Oid can be found in the device mib file. 

## Plugin Configuration
	{
          "plugin": "snmp",
          "debug": false
    }
The plugin has the following configuration properties:

| Property          | Default  | Type    | Description                                 |
|:------------------|:---------|:--------|:--------------------------------------------|
| debug             | false    | Boolean | Debug mode. Writes debug messages to the pimatic log, if set to true |


## Device Configuration
The following device can be used:

#### SnmpSensor
The SnmpSensor displays the output of your specified command to the gui. 

	{
			"id": "snmp1",
			"class": "SnmpSensor",
			"name": "Snmp Sensor",
			"host": "",			
			"oid": ""
	}

| Property          | Default  | Type    | Description                                 |
|:------------------|:---------|:--------|:--------------------------------------------|
| host              | -        | String  | Hostname or IP address of target device |
| port 				| 161	   | Number	 | Port used by snmp
| oid	 			| - 	   | String	 | oid(s) which should be requested from target device |
| community			| "public" | String  | snmp community for read and/or write access  |
| interval 			| 60000    | Number  | The time interval in milliseconds at which the oid is queried |
| attributes		| -		   | Object  | Attributes are automatical saved to config for later support for rules | 

If you already created a SnmpSensor device and you change the oid later, all attributes from this device need to be deleted, before the new attributes are shown. 

The oid must be provied using this format: .x.xx.x.x.x.xxx - for example: .1.2.840.10006.300.43.1.3.0

## ToDo

* Add support for oid names as label
* Add automatic clearing of attributes if command was changed
* Add set funtion for rule usage
* Add autodiscover functionality

## History

See [Release History](https://github.com/thost96/pimatic-snmp/blob/master/History.md).

## License 

Copyright (c) 2016, Thorsten Reichelt and contributors. All rights reserved.

License: [GPL-2.0](https://github.com/thost96/pimatic-snmp/blob/master/LICENSE).