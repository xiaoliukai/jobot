Xmpp = require 'node-xmpp'
util = require 'util'

# FIXME There is a timing issue here as we are not sure to be registered before the server starts sending the presence messages.
# TODO Contribute this to the hubot-xmpp project
class XmppIdResolverSingleton

  instance = null
  
  @get: ( robot ) ->
    instance ?= new XmppIdResolver( robot )
  
  class XmppIdResolver
  
    constructor: ( robot ) ->
      @robot = robot
      
      # usermap.room.alias=real jid
      @usermap = {}
      
      unless process.env.HUBOT_XMPP_CONFERENCE_DOMAINS
        console.log "Warning: HUBOT_XMPP_CONFERENCE_DOMAINS was not set. Mapping groupchat user to real user jid will not be possible."
        return
      @groupchat_domains = process.env.HUBOT_XMPP_CONFERENCE_DOMAINS.split(',' )
      
      # Listen to presence messages
      @robot.adapter.client.on 'stanza', @read
    
    read: (stanza) =>
      switch stanza.name
        when 'presence'
          @readPresence stanza
      
    readPresence: (stanza) =>
      # xmpp doesn't add types for standard available mesages
      # note that upon joining a room, server will send available
      # presences for all members
      # http://xmpp.org/rfcs/rfc3921.html#rfc.section.2.2.1
      stanza.attrs.type ?= 'available'
  
      switch stanza.attrs.type
        when 'available'
          # jid.user@jid.domain/jid.resource
          from_jid = new Xmpp.JID(stanza.attrs.from)
          
          # Process only goup chat
          return unless from_jid.domain in @groupchat_domains
          
          # Get the real JID (see http://xmpp.org/extensions/xep-0045.html#enter-nonanon)
          realJIDAttribute = stanza.getChild('x', 'http://jabber.org/protocol/muc#user')?.getChild('item')?.attrs?.jid
          
          unless realJIDAttribute
            console.lgo "Could not get real JID for group chat. Make sure the server is configured to bradcast real jid for groupchat"
          
          # Keep the mapping
          room = "#{from_jid.user}@#{from_jid.domain}"
          alias = "#{from_jid.resource}"
          # Keep only the user@domain part of the real jid
          realJID = new Xmpp.JID( realJIDAttribute )
          @usermap[room]?={}
          @usermap[room][alias]="#{realJID.user}@#{realJID.domain}"
          
          console.log "#{from_jid.resource} in #{from_jid.user}@#{from_jid.domain} is actually #{realJID.user}@#{realJID.domain}"
  
          
    #
    # Public API:
    #
          
    getRealJIDFromGroupchatJID: ( jid ) =>
      jid = new Xmpp.JID( jid )
      return @getRealJIDFromRoomAndAlias "#{jid.user}@#{jid.domain}", jid.resource
    
    getRealJIDFromRoomAndAlias: (room, alias) =>
      return null unless @usermap[room]
      return @usermap[room][alias]

module.exports = (robot) ->
  XmppIdResolverSingleton.get( robot )