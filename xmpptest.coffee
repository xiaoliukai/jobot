Xmpp = require 'node-xmpp'
util = require 'util'

@client = new Xmpp.Client
  reconnect: true
  jid: 'testbot@mdarveau.usine.8d.com'
  password: 'testbot'
  host: 'localhost'
  port: 5222
  legacySSL: process.env.HUBOT_XMPP_LEGACYSSL
  preferredSaslMechanism: process.env.HUBOT_XMPP_PREFERRED_SASL_MECHANISM

@parseRoom = (room) ->
  index = room.indexOf(':')
  return {
    jid:      room.slice(0, if index > 0 then index else room.length)
    password: if index > 0 then room.slice(index+1) else false
  }

@joinRoom = (room) ->
  @client.send do =>
    util.inspect "Joining #{room.jid}/testbot", {depth: 10, colors: true}

    el = new Xmpp.Element('presence', to: "#{room.jid}/testbot" )
    x = el.c('x', xmlns: 'http://jabber.org/protocol/muc' )
    x.c('history', seconds: 1 ) # prevent the server from confusing us with old messages
                                # and it seems that servers don't reliably support maxchars
                                # or zero values
    if (room.password) then x.c('password').t(room.password)
    return x
  
@client.on 'error', (param) =>
  console.log 'Error:'
  console.log util.inspect( param, {depth: 10, colors: true} )
      
@client.on 'online', (param) =>
  console.log 'Online:'
  console.log util.inspect( param, {depth: 10, colors: true} )
  
  @client.send new Xmpp.Element('presence')
  @joinRoom( @parseRoom( 'testing@conference.mdarveau.usine.8d.com' ) )
   
@client.on 'stanza', (param) =>
  console.log 'Stanza:'
  console.log util.inspect( param, {depth: 10, colors: true} )
  
@client.on 'offline', (param) =>
  console.log 'Offline:'
  console.log util.inspect( param, {depth: 10, colors: true} )
