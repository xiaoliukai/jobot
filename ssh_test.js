var control = require( 'control' )

var shared = Object.create( control.controller ), addresses = [ 'localhost' ]
shared.user = 'mdarveau'
//shared.sshOptions = ['-p 922']
var controllers = control.controllers( addresses, shared )

for ( i = 0, l = controllers.length; i < l; i += 1 ) {
    controller = controllers[i]
    controller.ssh( 'date', function(data){
        console.log(data)
        console.log(arguments)
    } )
}

// TODO test with https://github.com/mscdex/ssh2