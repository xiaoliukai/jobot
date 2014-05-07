#!/bin/sh

HOSTNAME=`hostname`

#export HUBOT_LOG_LEVEL=debug

export HUDSON_TEST_MANAGER_URL="https://solic1.dev.8d.com:8443"

# Set path to adapter since we are using npm link for hubot dependency. See Readme
export HUBOT_ADAPTER_PATH=`pwd`/node_modules/

export HUBOT_XMPP_USERNAME=hubot@${HOSTNAME}
export HUBOT_XMPP_CONFERENCE_DOMAINS=conference.${HOSTNAME}
export HUBOT_XMPP_PASSWORD=hubot
export HUBOT_XMPP_ROOMS=deploy@conference.${HOSTNAME}
export HUBOT_XMPP_HOST=localhost
export HUBOT_XMPP_PORT=5222
export I18N_WATCH_WORKDIR=.hubot/

./bin/hubot -n jobot -a xmpp