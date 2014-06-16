# Description:
#  Display log for jobot
#
# Commands:
#
#   hubot display log <n>- Print jobot logs <n> last lines of jobot.log, default 100 lines
#   hubot display old log <n> from <%m_%d_%y> at <%H:%M> - Print the last lines of <%m_%d_%y-%H:%M>.log
#   hubot show log - Print a list of available logs.


fs = require 'fs'
module.exports = (robot) ->

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

  robot.respond /show log/i, (msg) ->
    respond = ""
    try
      dir_log = fs.readdirSync "#{process.env.JOBOT_LOG}"
      respond += "#{name} \n" for name in dir_log
    catch err then respond = "oups i'll fix this #{err}"
    finally
      msg.send respond
