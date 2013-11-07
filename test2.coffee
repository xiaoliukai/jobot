jsonString = "{\"users\":{\"Manuel Darveau\":{\"id\":\"Manuel Darveau\",\"name\":\"Manuel Darveau\",\"type\":\"groupchat\",\"room\":\"deploy@conference.manuel-darveaus-imac.local\"},\"Manuel-Darveaus-iMac-5\":{\"id\":\"Manuel-Darveaus-iMac-5\",\"name\":\"Manuel-Darveaus-iMac-5\",\"type\":\"chat\",\"room\":\"mdarveau@jabber.8d.com\"},\"Manuel-Darveaus-iMac\":{\"id\":\"Manuel-Darveaus-iMac\",\"name\":\"Manuel-Darveaus-iMac\",\"type\":\"chat\",\"room\":\"mdarveau@manuel-darveaus-imac.local\"},\"Hubot2\":{\"id\":\"Hubot2\",\"room\":\"deploy@conference.manuel-darveaus-imac.local\",\"jid\":\"deploy@conference.manuel-darveaus-imac.local/Hubot2\",\"name\":\"Hubot2\"}},\"_private\":{}}"

data = JSON.parse( jsonString )

console.log data