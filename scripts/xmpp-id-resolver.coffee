Xmpp    = require 'node-xmpp'
util = require 'util'

module.exports = ( robot ) ->
  
  @readPresence = (stanza) =>
    jid = new Xmpp.JID(stanza.attrs.from)
    bareJid = jid.bare().toString()

    console.log "bareJid is '#{bareJid}'"
    
    # xmpp doesn't add types for standard available mesages
    # note that upon joining a room, server will send available
    # presences for all members
    # http://xmpp.org/rfcs/rfc3921.html#rfc.section.2.2.1
    stanza.attrs.type ?= 'available'

    # Parse a stanza and figure out where it came from.
    getFrom = (stanza) =>
      if bareJid not in ['deploy@conference.manuel-darveaus-imac.local']
        from = stanza.attrs.from
      else
        # room presence is stupid, and optional for some anonymous rooms
        # http://xmpp.org/extensions/xep-0045.html#enter-nonanon
        from = stanza.getChild('x', 'http://jabber.org/protocol/muc#user')?.getChild('item')?.attrs?.jid
      return from

    switch stanza.attrs.type
      when 'available'
        # for now, user IDs and user names are the same. we don't
        # use full JIDs as user ID, since we don't get them in
        # standard groupchat messages
        from = getFrom(stanza)
        console.log "User id is '#{from}'"
        return if not from?

        [room, from] = from.split '/'

        # ignore presence messages that sometimes get broadcast
        console.log "In room '#{room}'"
        #return if not @messageFromRoom room

        console.log "With jid '#{jid.toString()}'"

        console.log "jid #{jid.toString()} in room #{bareJid} is actually jid #{new Xmpp.JID(getFrom(stanza)).bare().toString()}"

  @read = (stanza) =>
    console.log 'xmpp-Received'
    console.log util.inspect stanza, {depth: null, colors: true}
    
    switch stanza.name
      when 'presence'
        @readPresence stanza
    
  robot.adapter.client.on 'stanza', @.read
  return