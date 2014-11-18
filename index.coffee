# # MPBasic
# ### extends [EventEmitter](http://nodejs.org/api/events.html)
#
# ### Exports: *Function*
#
# This is a general basic class. It inculdes some methods that are often usefull.
# It integrates logging, error handling getter/setter, ...
# 
# **Example:**
# 	
# 	Config = require( "./path/to/config/module" );
# 	class FooClass extends require( "mpbasic" )( Config )
#		initialize: =>
#			@debug "init"
#	
#	new FooClass() // -> DEBUG FooClass - Nov 07 2014 15:42:14 - init
# 

# **npm modules**
_ = require('lodash')._
extend = require('extend')
colors = require('colors')

# define a fallback if no config object has been passed.
fallbackCnf = 
	get: ( name, logging = false )->

		_cnf = {}
		if logging

			logging = 
				logging:
					severity: process.env[ "severity_#{name}"] or @severity
					severitys: "fatal,error,warning,info,debug".split( "," )
			return extend( true, {}, logging, _cnf )
		else
			return _cnf

module.exports = ( config = fallbackCnf )->
	
	# # Basic Module
	# ### extends [EventEmitter]
	# Basic module to handle errors and initialize modules
	return class Basic extends require('events').EventEmitter
		# ## internals
		
		# make the deep extend availible for all modles
		extend: extend

		# **defaults** *Function* basic object to hold config defaults. Will be overwritten by the constructor options
		defaults: =>
			return {}

		###	
		## constructor 

		`new Baisc( options )`
		
		Basic constructor. Define the configuration by options and defaults, init logging and init the error handler

		@param {Object} options Basic config object

		###
		constructor: ( options = {} )->
			@on "_log", @_log

			@getter "classname", ->
				return @constructor.name.toLowerCase()

			@config = extend( true, {}, @defaults(), config.get( @_config_name or @classname, true ), options )

			# init errors
			@_initErrors()

			@initialize( options )

			@debug "loaded"
			return

		# 
		# useage:
		
		
		###
		## mixin
		
		`mpbasic.mixin( mixins... )`
		
		Method to include other class methods to this class.		

		@param { Class } mixins... One or more classes as arguments 
		
		@api public
		###
		# **Example:**
		# 
		# 	class Foo
		# 		bar: ->
		# 		console.log( 42 )
		# 		return @
		#
		# 	class Lorem extends require( "mpbasic" )()
		# 		constructor: ->
		# 			@mixin( Foo )
		# 		return
		# 			run: -> return 23
		#	
		# 	new Lorem().bar().run() # -> log: 42 ; return 23
		#
		mixin: (mixins...)=>
			if mixins?.length
				for mxn in mixins
					for _fnname, fn of mxn.prototype when _fnname isnt "constructor"
						@[ _fnname ] = fn
			return

		###
		## initialize
		
		`basic.initialize()`
		
		Overwritible Method to initialize the module

		@param {Object} options Basic config object passed to constructor
		
		@api public
		###
		initialize: ( options )=>
			return

		###
		## define
		
		`basic.define( prop, fnGet [, fnSet] )`
		
		Helper to define getter and setter methods fot a property
		
		@param { String } prop Property name 
		@param { Function|Object } fnGet Get method or a object with `get` and `set` 
		@param { Function } [fnSet] Set method

		@api public
		###
		define: ( prop, fnGet, fnSet, writable = true, enumerable = true )=>
			_oGetSet = 
				enumerable: enumerable
				writable: writable

			if _.isFunction( fnGet )
				# set the `defineProperty` object
				_oGetSet = 
					get: fnGet
				_oGetSet.set = fnSet if fnSet? and _.isFunction( fnSet )
			else
				_oGetSet.value = fnGet
			
			# define by object
			Object.defineProperty @, prop, _oGetSet
			return

		###
		## getter
		
		`basic.getter( prop, fnGet )`
		
		Shortcut to define a getter
		
		@param { String } prop Property name 
		@param { Function } fnGet Get method 
		
		@api public
		###
		getter: ( prop, _get, enumerable = true )=>
			_obj = 
				enumerable: enumerable
				#writable: false

			if _.isFunction( _get )
				_obj.get = _get
			else
				_obj.value = _get
			Object.defineProperty @, prop, _obj
			return

		###
		## setter
		
		`basic.setter( prop, fnSet )`
		
		Shortcut to define a setter
		
		@param { String } prop Property name 
		@param { Function } fnSet Get method 
		
		@api public
		###
		setter: ( prop, fnGet, enumerable = true )=>
			Object.defineProperty @, prop, set: fnGet, enumerable: enumerable, writable: true
			return	

		###
		## _waitUntil
		
		`basic._waitUntil( method[, key][, context] )`
		
		Wrapper method to create a methos thas is only called until the `@{key}`is true or an event `{key}` has bin emitted.
		Usually this is used to generate a method that will wait until the modules/class is ready.
		
		@param { Function } method The function to call.
		@param { String } [ key="ready" ] the key to listen for.
		@param { Context } [context={self}] The context to lsiten to the key. Per default it is the instance it self `@` or `this`.
		
		@api public
		###
		_waitUntil: ( method, key = "ready", context = @ )=>
			return =>
				args = arguments
				if context[ key ]
					method.apply( @, args )
				else
					context.once key, =>
						method.apply( @, args )
						return
				return

		# handle a error
		###
		## _handleError
		
		`basic._handleError( cb, err [, data] )`
		
		Baisc error handler. It creates a true error object and returns it to the callback, logs it or throws the error hard
		
		@param { Function|String } cb Callback function or NAme to send it to the logger as error 
		@param { String|Error|Object } err Error type, Obejct or real error object
		
		@api private
		###
		_handleError: ( cb, err, data = {}, errExnd )=>
			# try to create a error Object with humanized message
			if _.isString( err )
				_err = new Error()
				_err.name = err
				_err.message = @_ERRORS?[ err ][ 1 ]?( data ) or "unkown"
				_err.statusCode = @_ERRORS?[ err ][ 0 ] or 500
				_err.customError = true
			else 
				_err = err

			if errExnd?
				_err.data = errExnd

			for _k, _v of data 
				_err[ _k ] = _v

			if _.isFunction( cb )
				#@log "error", "", _err
				cb( _err )
			else if _.isString( cb )
				@log "error", cb, _err
			else if cb is true
				return _err
			else	
				throw _err
			return _err

		###
		## log
		
		`base.log( severity, code [, content1, content2, ... ] )`
		
		write a log to the console if the current severity matches the message severity
		
		@param { String } severity Message severity
		@param { String } code Simple code the describe/label the output
		@param { Any } [contentN] Content to append to the log
		
		@api public
		###
		log: ( severity, code, content... )=>
			args = [ "_log", severity, code ]
			@emit.apply( @, args.concat( content ) ) 
			return

		###
		## _log
		
		`base._log( severity, code [, content1, content2, ... ] )`
		
		write a log to the console if the current severity matches the message severity
		
		@param { String } severity Message severity
		@param { String } code Simple code the describe/label the output
		@param { Any } [contentN] Content to append to the log
		
		@api private
		###
		_log: ( severity, code, content... )=>
			# get the severity and throw a log event
			
			if @_checkLogging( severity )
				_tmpl = "%s %s - #{ new Date().toString()[4..23]} - %s "

				args = [ _tmpl, severity.toUpperCase(), @_logname(), code ]

				if content.length
					args[ 0 ] += "\n"
					for _c in content
						args.push _c

				switch severity
					when "fatal"
						args[ 0 ] = args[ 0 ].red.bold.inverse
						console.error.apply( console, args )
						for arg in args when arg instanceof Error
							console.log arg.stack
							return
						console.trace()
					when "error"
						args[ 0 ] = args[ 0 ].red.bold
						console.error.apply( console, args )
					when "warning"
						args[ 0 ] = args[ 0 ].yellow.bold
						console.warn.apply( console, args )
					when "info"
						args[ 0 ] = args[ 0 ].blue.bold
						console.info.apply( console, args )
					when "debug"
						args[ 0 ] = args[ 0 ].green.bold
						console.log.apply( console, args )
					else
		
			return

		###
		## _logname
		
		`basic._logname()`
		
		Helper method to overwrite the name displayed withing the console output
		
		@param { String }  Desc 
		@param { Function }  Callback function 
		
		@return { String } Return Desc 
		
		@api private
		###
		_logname: =>
			return @constructor.name

		###
		## fatal
		
		`index.fatal( code, content... )`
		
		Shorthand to output a **fatal** log
		
		@param { String } code Simple code the describe/label the output
		@param { Any } [contentN] Content to append to the log
		
		@api public
		###
		fatal: ( code, content... )=>
			args = [ "_log", "fatal", code ]
			@emit.apply( @, args.concat( content ) ) 
			return

		###
		## error
		
		`index.error( code, content... )`
		
		Shorthand to output a **error** log
		
		@param { String } code Simple code the describe/label the output
		@param { Any } [contentN] Content to append to the log
		
		@api public
		###
		error: ( code, content... )=>
			args = [ "_log", "error", code ]
			@emit.apply( @, args.concat( content ) ) 
			return

		###
		## warning
		
		`index.warning( code, content... )`
		
		Shorthand to output a **warning** log
		
		@param { String } code Simple code the describe/label the output
		@param { Any } [contentN] Content to append to the log
		
		@api public
		###
		warning: ( code, content... )=>
			args = ["_log",  "warning", code ]
			@emit.apply( @, args.concat( content ) ) 
			return

		###
		## info
		
		`index.info( code, content... )`
		
		Shorthand to output a **info** log
		
		@param { String } code Simple code the describe/label the output
		@param { Any } [contentN] Content to append to the log
		
		@api public
		###
		info: ( code, content... )=>
			args = [ "_log", "info", code ]
			@emit.apply( @, args.concat( content ) ) 
			return

		###
		## debug
		
		`index.debug( code, content... )`
		
		Shorthand to output a **debug** log
		
		@param { String } code Simple code the describe/label the output
		@param { Any } [contentN] Content to append to the log
		
		@api public
		###
		debug: ( code, content... )=>
			args = [ "_log", "debug", code ]
			@emit.apply( @, args.concat( content ) ) 
			return

		###
		## _checkLogging
		
		`basic._checkLogging( severity )`
		
		Helper to check if a log will be written to the console
		
		@param { String } severity Message severity
		
		@return { Boolean } Flag if the severity is allowed to write to the console
		
		@api private
		###
		_checkLogging: ( severity )=>
			if not @_logging_iseverity?
				@_logging_iseverity = @config.logging.severitys.indexOf( @config.logging.severity )

			iServ = @config.logging.severitys.indexOf( severity )
			if @config.logging.severity? and iServ <= @_logging_iseverity
				true
			else
				false

		###
		## _initErrors
		
		`basic._initErrors(  )`
		
		convert error messages to underscore templates
		
		@api private
		###
		_initErrors: =>
			@_ERRORS = @ERRORS()
			for key, msg of @_ERRORS
				if not _.isFunction( msg[ 1 ] )
					@_ERRORS[ key ][ 1 ] = _.template( msg[ 1 ] )
		
			return

		###
		## ERRORS
		
		`passwordless.ERRORS()`
		
		Error detail mappings
		
		@return { Object } Return A Object of error details. Format: `"ERRORCODE":[ ststudCode, "Error detail" ]` 
		
		@api private
		###
		ERRORS: =>
			"ENOTIMPLEMENTED": [ 501, "This function is planed but currently not implemented" ]