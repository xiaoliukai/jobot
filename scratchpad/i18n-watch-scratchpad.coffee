fs = require 'fs'
path = require 'path'
exec = require( 'child_process' ).exec
async = require 'async'
xpath = require 'xpath'
dom = require( 'xmldom' ).DOMParser
require( "natural-compare-lite" )

rootworkdir = '/tmp/i18n'
fs.mkdirSync rootworkdir unless fs.existsSync rootworkdir

gitCommand = ( absworkdir, command ) ->
  command = "git "
  command += "--work-tree=#{absworkdir} --git-dir=#{absworkdir}/.git " if absworkdir
  command += command
  return command

gitStep = ( absworkdir, params ) ->
  return  ( previousstdout, callback ) ->
    callback = previousstdout unless callback
    command = gitCommand absworkdir, params
    exec command, ( error, stdout, stderr ) ->
      console.log command
      console.log stdout unless error
      console.log "Error #{error} : stderr: #{stderr}" if error
      callback error, stdout

processProject = ( info ) ->
  absworkdir = path.join rootworkdir, info.workdir
      
  if info.inprogress
    console.log "#{info.giturl} branch #{info.branch} is already in progress"
    return
  
  info.inprogress = true
        
  if fs.existsSync absworkdir
    console.log "Checking for updates"
    async.waterfall [
      # Pull latest changes
      gitStep( absworkdir, "pull" ) ,
      
      # Check for new commites
      gitStep( absworkdir, 'log --pretty=format:\"{\\"hash\\":\\"%H\\", \\"author\\":\\"%an\\", \\"date\\":\\"%ar\\"},\" #{info.lastknowncommit}..' ),
      
      # Parse output
      ( result, callback ) ->
        gitlog = JSON.parse "[#{result.slice(0, - 1)}]"
        console.log "New commits:"
        for log in gitlog
          console.log "  #{log.hash}"
        latesthash = gitlog[0]?.hash
  
        # Check if there is a new commit. If not, return and it will abort the chain.
        if info.lastknowncommit == latesthash
          info.inprogress = false
          return
        
        console.log "New commit for #{info.giturl} branch #{info.branch}"

        # Call maven to extract i18n keys
        command = "mvn -f #{absworkdir}/pom.xml -pl ftk-i18n-extract -am -P i18n-xliff-extract clean compile process-resources"
        exec command, {}
          timeout: 10*60*1000 # 10 minutes
          maxBuffer: 1*1024*1024 # 1 MB
        ,( error, stdout, stderr ) ->
          # TODO Handle failure because of compile fail or other. Check error.code
          console.log command
          console.log stdout unless error
          console.log "Error #{error} : stderr: #{stderr}" if error
          callback error, latesthash
      ,
      ( latesthash, callback ) ->
        getUntranslatedKeyInProject absworkdir, (err, untranslatedKeys) ->
          callback err, latesthash, untranslatedKeys
          
    ], ( err, latesthash, untranslatedKeys ) ->
      if err
        console.log err
      else
        for key in untranslatedKeys
          console.log key
        info.lastknowncommit = latesthash
        info.inprogress = false
        # TODO store info
  
  else
    # TODO Clone inline with request
    console.log "Cloning repo #{info.giturl}"
    async.waterfall [
      # Pull latest changes
      gitStep( null, "clone -b #{info.branch} #{info.giturl} #{absworkdir}" ) ,
      
      # Check for new commites
      gitStep( absworkdir, 'log --pretty=format:\"{\\"hash\\":\\"%H\\"} -n1\"' ),
      
      # Parse output
      ( result, callback ) ->
        gitlog = JSON.parse "#{result}"
        info.lastknowncommit = gitlog.hash
        callback err

    ], ( err ) ->
      if err
        console.log err
      else
        # TODO store info
        console.log "Clone completed"

getUntranslatedKeyInProject = ( project, callback ) ->
  fs.readFile Path.resolve( project, 'ftk-i18n/src/main/xliff/SolsticeConsoleStrings_en.xlf' ), ( err, data ) ->
    if err
      callback ( err )
      return
    dom = new dom().parseFromString( data.toString() )
    nodes = xpath.select( "//trans-unit[target='']/@id", dom )
    untranslatedKeys = []
    for id in nodes
      untranslatedKeys.push id.value
    untranslatedKeys.sort String.naturalCompare
    callback null, untranslatedKeys
        
info =
  'giturl': 'https://github.com/MacKeeper/testi18nwatch.git'
  'branch': 'master'
  'workdir': '123'
        
processProject info