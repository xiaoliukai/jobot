# Description:
#   Inspect the data in redis easily
#
# Commands:
#   hubot show users - Display all users that hubot knows about
#   hubot show storage - Display the contents that are persisted in the brain
#   hubot time - display the server time for hubot
#   hubot show log - check for logs

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


  robot.respond /show log (\d+)?/i, (msg) ->
    endline = msg.match[1]
    respond = ""
    log = fs.readFileSync "#{process.env.JOBOT_LOG}/jobot.log"
    arr = log.toString().split('\n')
    arr =  if endline > 0 then arr[-endline..] else arr[-150..]
    respond += "#{line} \n" for line in arr
    msg.send respond
