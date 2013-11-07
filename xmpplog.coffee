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
  
@readPresence = (stanza) =>
  jid = new Xmpp.JID(stanza.attrs.from)
  bareJid = jid.bare().toString()

  console.log "Received presence stanza. from='#{stanza.attrs.from}', realjid='#{stanza.getChild('x', 'http://jabber.org/protocol/muc#user')?.getChild('item')?.attrs?.jid}'"
  
  ## xmpp doesn't add types for standard available mesages
  ## note that upon joining a room, server will send available
  ## presences for all members
  ## http://xmpp.org/rfcs/rfc3921.html#rfc.section.2.2.1
  #stanza.attrs.type ?= 'available'
  #
  ## Parse a stanza and figure out where it came from.
  #getFrom = (stanza) =>
  #  if bareJid not in ['deploy@conference.manuel-darveaus-imac.local']
  #    from = stanza.attrs.from
  #  else
  #    # room presence is stupid, and optional for some anonymous rooms
  #    # http://xmpp.org/extensions/xep-0045.html#enter-nonanon
  #    from = stanza.getChild('x', 'http://jabber.org/protocol/muc#user')?.getChild('item')?.attrs?.jid
  #  return from
  #
  #switch stanza.attrs.type
  #  when 'available'
  #    # for now, user IDs and user names are the same. we don't
  #    # use full JIDs as user ID, since we don't get them in
  #    # standard groupchat messages
  #    from = getFrom(stanza)
  #    console.log "User id is '#{from}'"
  #    return if not from?
  #
  #    [room, from] = from.split '/'
  #
  #    # ignore presence messages that sometimes get broadcast
  #    console.log "In room '#{room}'"
  #    #return if not @messageFromRoom room
  #
  #    console.log "With jid '#{jid.toString()}'"
  #
  #    console.log "jid #{jid.toString()} in room #{bareJid} is actually jid #{new Xmpp.JID(getFrom(stanza)).bare().toString()}"

@read = ( param ) =>
  console.log 'Stanza:'
  console.log param.toString

  switch stanza.name
    when 'presence'
      @readPresence stanza
  
@offline = ( param ) =>
  console.log 'Offline:'
  console.log util.inspect param, {depth: null, colors: true}
  
@client.on 'error', @.error
@client.on 'online', @.online
@client.on 'stanza', @.read
@client.on 'offline', @.offline