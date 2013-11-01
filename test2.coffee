Fs             = require 'fs'
Path           = require 'path'

path = '/Users/mdarveau/workspace/jobot/scripts'
file = 'hudson-test-manager.js'

ext  = Path.extname file
full = Path.join path, Path.basename(file, ext)

console.log Path.join( path, Path.basename( file, ext ) + '.coffee' ) 
console.log Fs.existsSync( Path.join( path, Path.basename( file, ext ) + '.coffee' ) )
console.log ext is '.js' and not Fs.exists( Path.join( path, Path.basename( file, ext ) + '.coffee' ) )

if ext is '.coffee' or ( ext is '.js' and not Fs.existsSync( Path.join( path, Path.basename( file, ext ) + '.coffee' ) ) )
  console.log 'load'
else 
  console.log 'no load'