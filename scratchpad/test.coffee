fs = require 'fs'
path = require 'path'
async = require 'async'
xpath = require 'xpath'
dom = require( 'xmldom' ).DOMParser
exec = require( 'child_process' ).exec

# Call maven to extract i18n keys
command = "mvn -f /tmp/i18n/123/pom.xml -pl ftk-i18n-extract -am -P i18n-xliff-extract clean compile process-resources"
exec command,
  timeout: 10 * 60 * 1000 # 10 minutes
  maxBuffer: 1 * 1024 * 1024 # 1 MB
, ( error, stdout, stderr ) ->
  # TODO Handle failure because of compile fail or other. Check error.code
  console.log command
  console.log stdout unless error
  console.log "Error:'#{error}', stdout: #{stdout}, stderr: #{stderr}" if error