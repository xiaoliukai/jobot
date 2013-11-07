#!/bin/sh

HOSTNAME=`hostname`

export HUBOT_XMPP_USERNAME=hubot@${HOSTNAME}
export HUBOT_XMPP_PASSWORD=hubot
export HUBOT_XMPP_ROOMS=deploy@conference.${HOSTNAME}
export HUBOT_XMPP_HOST=localhost
export HUBOT_XMPP_PORT=5222

./bin/hubot -i jobot -a xmpp