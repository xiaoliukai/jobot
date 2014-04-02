fs = require 'fs'
#path = require 'path'
#exec = require( 'child_process' ).exec
#async = require 'async'
#xpath = require 'xpath'
#dom = require( 'xmldom' ).DOMParser
#require( "natural-compare-lite" )

I18nWatcher = require('../scripts/i18n-watch')

rootworkdir = '/tmp/i18n'
fs.mkdirSync rootworkdir unless fs.existsSync rootworkdir
      
info =
  giturl: 'https://github.com/MacKeeper/testi18nwatch.git'
  branch: 'master'
  workdir: '123'
  
robot =
  respond: (  ) ->

i18n = new I18nWatcher( robot, true )
  
i18n.processProject info