Xmpp = require 'node-xmpp'
util = require 'util'

options =
  username: 'hubot@manuel-darveaus-imac.local'
  password: 'hubot'
  host: 'localhost'
  port: 5222
  keepaliveInterval: 30000 # ms interval to send whitespace to xmpp server
  legacySSL: process.env.HUBOT_XMPP_LEGACYSSL
  preferredSaslMechanism: process.env.HUBOT_XMPP_PREFERRED_SASL_MECHANISM

@client = new Xmpp.Client
  reconnect: true
  jid: options.username
  password: options.password
  host: options.host
  port: options.port
  legacySSL: options.legacySSL
  preferredSaslMechanism: options.preferredSaslMechanism

@error = ( param ) =>
  console.log 'Error:'
  console.log util.inspect param, {depth: null, colors: true}

@online = ( param ) =>
  console.log 'Online:'
  console.log util.inspect param, {depth: null, colors: true}
  
  # Request roster
  # <iq from='crone1@shakespeare.lit/desktop'
  #   id='member3'
  #   to='coven@chat.shakespeare.lit'
  #   type='get'>
  #   <query xmlns='http://jabber.org/protocol/muc#admin'>
  #     <item affiliation='member'/>
  #   </query>
  # </iq>
  request = new Xmpp.Element('iq',
    from: 'hubot@manuel-darveaus-imac.local'
    id: 'member1'
    to: 'deploy@conference.manuel-darveaus-imac.local'
    type: 'get'
  )
  request.c('query',
    xmlns: 'http://jabber.org/protocol/muc#user'
  ).c('item',
    affiliation: 'member'
  )
  console.log "sending: #{request}"
  @client.send request
  
@read = ( param ) =>
  console.log 'Stanza:'
  console.log util.inspect param, {depth: null, colors: true}
  
@offline = ( param ) =>
  console.log 'Offline:'
  console.log util.inspect param, {depth: null, colors: true}
  
@client.on 'error', @.error
@client.on 'online', @.online
@client.on 'stanza', @.read
@client.on 'offline', @.offline