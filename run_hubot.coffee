Hubot    = require 'hubot'

Fs       = require 'fs'
Path     = require 'path'

robot = Hubot.loadBot '', 'xmpp', true, 'jobot'

loadScripts = ->
  scriptsPath = Path.resolve ".", "scripts"
  robot.load scriptsPath

  hubotScripts = Path.resolve ".", "hubot-scripts.json"
  Fs.exists hubotScripts, (exists) ->
    if exists 
      Fs.readFile hubotScripts, (err, data) ->
        if data.length > 0
          try
            scripts = JSON.parse data 
            scriptsPath = Path.resolve "node_modules", "hubot-scripts", "src", "scripts"
            robot.loadHubotScripts scriptsPath, scripts
          catch err
            console.error "Error parsing JSON data from hubot-scripts.json: #{err}"
            process.exit(1)

  externalScripts = Path.resolve ".", "external-scripts.json"
  Fs.exists externalScripts, (exists) ->
    if exists
      Fs.readFile externalScripts, (err, data) ->
        if data.length > 0
          try
            scripts = JSON.parse data
          catch err
            console.error "Error parsing JSON data from external-scripts.json: #{err}"
            process.exit(1)
          robot.loadExternalScripts scripts

robot.adapter.on 'connected', loadScripts

robot.run()