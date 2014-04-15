Xmpp = require 'node-xmpp'
util = require 'util'

options =
  username: 'hubot@Manuel-Darveaus-iMac.local'
  password: 'hubot'
  host: 'localhost'
  port: 5222
  keepaliveInterval: 30000
  legacySSL: process.env.HUBOT_XMPP_LEGACYSSL
  preferredSaslMechanism: process.env.HUBOT_XMPP_PREFERRED_SASL_MECHANISM
  disallowTLS: process.env.HUBOT_XMPP_DISALLOW_TLS

@client = new Xmpp.Client
  reconnect: true
  jid: options.username
  password: options.password
  host: options.host
  port: options.port
  legacySSL: options.legacySSL
  preferredSaslMechanism: options.preferredSaslMechanism
  disallowTLS: options.disallowTLS

@client.on 'error', ( err ) =>
  console.log "Error #{err}"

@client.on 'online', () =>
  console.log "Online"

  presence = new Xmpp.Element 'presence'
  presence.c('nick', xmlns: 'http://jabber.org/protocol/nick').t('hubot')
  @client.send presence
  
  params =
    to: 'mdarveau@Manuel-Darveaus-iMac.local'
    type: 'direct'

  #message = new Xmpp.Element( 'message', params )
  #message.c( 'body' ).t( 'testing!' )
  #message.c( 'html', {xmlns:'http://jabber.org/protocol/xhtml-im'} )
  #.c('body', {xmlns:'http://www.w3.org/1999/xhtml'})
  #.c('p').t('Hey look:').c('a', {href:'http://www.amazon.com'}).t('apple.com')
  
  message = new Xmpp.Element( 'message', params )
  body = message.c( 'html', {xmlns:'http://jabber.org/protocol/xhtml-im'} ).c('body', {xmlns:'http://www.w3.org/1999/xhtml'})
  body.t('Hey look:').c('br')
  body.t('  1 - Test a' ).c('b').t(' unassigned').up().c('br').up()
  body.t('  2 - Test b' ).c('br').up()
  body.t('  3 - Test c' )
  
  @client.send message
  
@client.on 'stanza', ( stanza ) =>
  console.log "Stanza: #{stanza}"

@client.on 'offline', () =>
  console.log "Offline"

#<message type="chat" id="purple575994cc" to="hubot@manuel-darveaus-imac.local/5445ff6c" from="mdarveau@manuel-darveaus-imac.local/Manuel-Darveaus-iMac" xmlns:stream="http://etherx.jabber.org/streams">
#    <body>Hey look: http://nodejs.org/api/process.html#process_process_exit_code</body>
#    <html xmlns="http://jabber.org/protocol/xhtml-im">
#        <body xmlns="http://www.w3.org/1999/xhtml">
#            <p>Hey look:
#                <a href="http://nodejs.org/api/process.html#process_process_exit_code">http://nodejs.org/api/process.html#process_process_exit_code</a>
#            </p>
#        </body>
#    </html>
#</message>
  


#presence = new Xmpp.Element 'presence'
#presence.c( 'nick', xmlns: 'http://jabber.org/protocol/nick' ).t( @robot.name )
#
#el = new Xmpp.Element( 'presence', to: "#{room.jid}/#{@robot.name}" )
#x = el.c( 'x', xmlns: 'http://jabber.org/protocol/muc' )
#x.c( 'history', seconds: 1 )
#
#var stanza = new xmpp.Element( 'presence', { type: 'chat'} )
#.c( 'show' ).t( 'chat' ).up()
#.c( 'status' )
#.t( 'Happily echoing your <message/> stanzas' )
#cl.send( stanza )