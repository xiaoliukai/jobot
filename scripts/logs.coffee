# Description:
#  Display log for jobot
#
# Commands:
#
#   hubot display log <n> - Print jobot logs <n> last lines of jobot.log, default 100 lines
#   hubot display old log <n> from <%m_%d_%y> at <%H:%M> - Print the last lines of <%m_%d_%y-%H:%M>.log
#   hubot show log - Print a list of available logs.
#   hubot clean log - Delete log files, keep the last one
#   hubot log size - Print the current size of hubot log directory.
exec = require( 'child_process' ).exec
fs = require 'fs'

module.exports = (robot) ->


  robot.respond /talk to me$/i, ( msg ) ->
  # Simply reply
    msg.reply "Hello #{msg.envelope.user.name}. Your private JID is #{msg.envelope.user.privateChatJID}"

  robot.respond /talk to me in private$/i, ( msg ) ->
    msg.envelope =
      user:
        privateChatJID : msg.envelope.user.privateChatJID
        type : 'chat'
    msg.send  "Hey #{msg.envelope.user.name}! You told me in room #{msg.envelope.user.room} to talk to you."

  robot.respond /display log( \d+)?/i, (msg) ->
#    msg.envelope.user = msg.envelope.user.privateChatJid
    msg.envelope.user.type = 'chat'
    endline = msg.match[1]
    respond = ""
    log = fs.readFileSync "#{process.env.JOBOT_LOG}/jobot.log"
    arr = log.toString().split('\n')
    arr =  if endline > 0 then arr[-endline..] else arr[-100..]
    respond += "#{line} \n" for line in arr
    msg.reply respond


  robot.respond /display old log( \d+)? from (\d\d_\d\d_\d\d) at (\d\d:\d\d)/i, (msg) ->
    msg.envelope.user.type = 'chat'
    respond = ""
    endline = msg.match[1]
    try
      log = fs.readFileSync "#{process.env.JOBOT_LOG}/#{msg.match[2]}-#{msg.match[3]}.log"
      console.log log.toString()
      arr = log.toString().split('\n')
      arr =  if endline > 0 then arr[-endline..] else arr[-100..]
      respond += "#{line} \n" for line in arr
    catch err then respond = "No such log #{err}"
    finally
      msg.reply respond

  robot.respond /show log/i, (msg) ->
    msg.envelope.user.type = 'chat'
    respond = "You can access the following files :\n"
    i=1
    try
      dir_log = fs.readdirSync "#{process.env.JOBOT_LOG}"
      respond += "#{i++}- #{name} \n" for name in dir_log when name isnt 'jobot.log'
    catch err then respond = "oups i'll fix this #{err}"
    finally
      msg.reply respond


  robot.respond /clean log/i, (msg) ->

    msg.reply "OK I will keep the last log."
    cmd = exec './scripts/shell/log.sh'
    cmd.stdout.on 'data', (data) ->
      for line in data.toString().split('\n')
        msg.reply  "#{line}"

    cmd.stderr.on 'data', (data) ->
      for line in data.toString().split('\n')
        msg.reply line

    cmd.on 'exit', (code) ->
      if code == 0
        msg.reply "Done."
      else
        msg.reply "Something went wrong"


  robot.respond /log size/, (msg) ->
    msg.envelope.user.type = 'chat'
    cmd  = exec "cd #{process.env.JOBOT_LOG} && du -hs"
    cmd.stdout.on 'data', (data) ->
      msg.reply  "#{data}"
