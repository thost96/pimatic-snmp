# Release History

* 20200428, v04.2 
	* added github actions with automated npm publish
	* updated dependencies to latest versions

* 20180206, v0.4.1
	* added Travis CI and updated readme

* 20161208, v0.4.0 
	* Added SnmpPresenceSensor
	* Updated README.md

* 20161202, v0.3.0
	* Added support for oid names as label
	* Added support for multiple oids at a single device
	* Updated README.md
	* Modified and minimized debug ouput

* 20161118, v0.2.1
	* Removed net-ping dependencies
	* Removed icmp scan of local networks for discovery
	* Updated README.md
	* Added netmask to dependencies
	* Added support for other networks then /24 using netmask
	* Fixed some typos

* 20161116, v0.2.0
	* Added auto discovery for snmp devices on local network
	* Update README.md
	* Added net-ping to dependencies
	* Added License to package.json

* 20161114, v0.1.3
	* Changed getNextAsync to getAsync 
	* Added option to modify snmp port
	* Fixed directly reading of data from device
	* Updated README.md

* 20161114, v0.1.2
	* Updated README.md
	* Fixed wrong oid type in device-config-schema.coffee

* 20161108, v0.1.1
	* Updated README.md
	* Fixed attrName using array to string
	* Released pimatic-snmp on npm

* 20161106, v0.1.0
	* Initial version