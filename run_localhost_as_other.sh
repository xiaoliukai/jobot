#!/bin/sh

export HUBOT_XMPP_USERNAME=other@manuel-darveaus-imac.local
export HUBOT_XMPP_PASSWORD=other
export HUBOT_XMPP_ROOMS=deploy@conference.manuel-darveaus-imac.local
export HUBOT_XMPP_HOST=localhost
export HUBOT_XMPP_PORT=5222

./bin/hubot -i jobot -a xmpp