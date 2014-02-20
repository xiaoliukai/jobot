# jobot set storage {"users":{"Manuel":{"id":"Manuel","room":"deploy@conference.manuel-darveaus-imac.local","jid":"deploy@conference.manuel-darveaus-imac.local/Manuel","privateChatJID":"mdarveau@manuel-darveaus-imac.local/Manuel-Darveaus-iMac","name":"Manuel","type":"groupchat"}},"_private":{"HudsonTestManagerBackend":{"projects":{"jobot_test":{"room":"deploy@conference.manuel-darveaus-imac.local","manager":"mdarveau@manuel-darveaus-imac.local","builds":{"jobot_test":{"lastbuildnumber":6}},"failedtests":{}}}}}}

moment = require 'moment'

m1 = moment()

s = JSON.stringify(m1)
console.log s

m2 = moment(s)

console.log s