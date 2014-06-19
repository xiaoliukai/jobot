# Description:
#   Inspect the data in redis easily
#
# Commands:
#   hubot show users - Display all users that hubot knows about
#   hubot show storage - Display the contents that are persisted in the brain
#   hubot time - display the server time for hubot


Util = require "util"
Moment = require 'moment'
fs = require 'fs'
module.exports = (robot) ->
  robot.respond /show storage$/i, (msg) ->
    output = JSON.stringify robot.brain.data, null, 4
    console.log output
    for line in output.split('\n')
      msg.reply line

  robot.respond /time$/i, (msg) ->
    output = "Server time is : " + Moment().format()
    msg.reply output

  robot.respond /set storage ([\s\S]*)$/i, (msg) ->
    backup = robot.brain.data
    console.log "Swapping brain value. Backup: #{JSON.stringify robot.brain.data, null, 4}"
    robot.brain.data = JSON.parse( msg.match[1] )
    robot.brain.save()
    msg.reply "Done, previous brain was #{JSON.stringify backup, null, 4}"

   robot.respond /ls$/i, (msg)->
       output = JSON.stringify robot.brain.data, null, '\t'
       for line in output.split('\n')
         msg.reply line

  robot.respond /show users$/i, (msg) ->
    response = ""

    for own key, user of robot.brain.data.users
      response += "id :#{user.id}, name :#{user.name}"
      response += " <#{user.email_address}>" if user.email_address
      response += "\n"
    msg.reply response
