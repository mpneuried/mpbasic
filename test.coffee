should = require( "should" )

class TestClass extends require( "./index.js")()
	
	defaults: =>
		@extend super,
			a: 1
			b: 2
	
	initialize: =>		
		should.exist( @config.a )
		@config.a.should.equal( 1 )
		should.exist( @config.b )
		@config.b.should.equal( 2 )
		return
		
	
new TestClass()

console.log "TESTS done!"
