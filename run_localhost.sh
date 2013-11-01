#!/bin/sh

export HUBOT_XMPP_USERNAME=hubot@manuel-darveaus-imac.local
export HUBOT_XMPP_PASSWORD=hubot
export HUBOT_XMPP_ROOMS=deploy@conference.manuel-darveaus-imac.local
export HUBOT_XMPP_HOST=localhost
export HUBOT_XMPP_PORT=5222

./bin/hubot -i jobot -a xmpp