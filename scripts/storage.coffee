# Description:
#   Inspect the data in redis easily
#
# Commands:
#   hubot show users - Display all users that hubot knows about
#   hubot show storage - Display the contents that are persisted in the brain
#   hubot time - display the server time for hubot
#   hubot display log <n>- Print jobot logs <n> last lines of jobot.log, default 100 lines
#   hubot display old log <n> from <%m_%d_%y> at <%H:%M> - Print the last lines of <%m_%d_%y-%H:%M>.log

Util = require "util"
Moment = require 'moment'
fs = require 'fs'
module.exports = (robot) ->
  robot.respond /show storage$/i, (msg) ->
    output = JSON.stringify robot.brain.data, null, 4
    console.log output
    msg.send output

  robot.respond /time$/i, (msg) ->
    output = "Server time is : " + Moment().format()
    msg.send output

  robot.respond /set storage ([\s\S]*)$/i, (msg) ->
    backup = robot.brain.data
    console.log "Swapping brain value. Backup: #{JSON.stringify robot.brain.data, null, 4}"
    robot.brain.data = JSON.parse( msg.match[1] )
    robot.brain.save()
    msg.send "Done, previous brain was #{JSON.stringify backup, null, 4}"

   robot.respond /ls$/i, (msg)->
       output = JSON.stringify robot.brain.data, null, '\t'
       msg.send output

  robot.respond /show users$/i, (msg) ->
    response = ""

    for own key, user of robot.brain.data.users
      response += "id :#{user.id}, name :#{user.name}"
      response += " <#{user.email_address}>" if user.email_address
      response += "\n"
    msg.send response


  robot.respond /display log( \d+)?/i, (msg) ->
    endline = msg.match[1]
    respond = ""
    log = fs.readFileSync "#{process.env.JOBOT_LOG}/jobot.log"
    arr = log.toString().split('\n')
    arr =  if endline > 0 then arr[-endline..] else arr[-100..]
    respond += "#{line} \n" for line in arr
    msg.send respond

  robot.respond /display old log( \d+)? from (\d\d_\d\d_\d\d) at (\d\d:\d\d)/i, (msg) ->
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
    msg.send respond
