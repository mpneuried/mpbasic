# # MPBasic - Default config
# ### extends [EventEmitter](http://nodejs.org/api/events.html)
#
# ### Exports: *Object*

# **npm modules**
extend = require('extend')

# define a fallback if no config object has been passed.
DefaultConfig =
	get: ( name, logging = false )->
		_cnf = {}
		if logging

			logging =
				logging:
					severity: process.env[ "severity" ] or process.env[ "severity_#{name}"] or @severity
					severitys: "fatal,error,warning,info,debug".split( "," )
			return extend( true, {}, logging, _cnf )
		else
			return _cnf

module.exports = DefaultConfig
