#!/bin/sh

HOSTNAME=`hostname`

export HUBOT_LOG_LEVEL=debug
coffee -c .

export HUDSON_TEST_MANAGER_URL="https://hudson.priv.8d.com:8443"
export TEAMCITY_TEST_MANAGER_URL="https://teamcity.priv.8d.com:8443"
# Set path to adapter since we are using npm link for hubot dependency. See Readme
export HUBOT_ADAPTER_PATH=`pwd`/node_modules/
export FILE_BRAIN_PATH=.
#export HUBOT_TEAMCITY_USERNAME='jobot'
#export HUBOT_TEAMCITY_PASSWORD='jobot'
export HUBOT_TEAMCITY_HOSTNAME='teamcity.priv.8d.com:8443'
export HUBOT_TEAMCITY_SCHEME='https'
export HUBOT_XMPP_USERNAME=hubot@${HOSTNAME}
export HUBOT_XMPP_CONFERENCE_DOMAINS=conference.${HOSTNAME}
export HUBOT_XMPP_PASSWORD=hubot
export HUBOT_XMPP_ROOMS=deploy@conference.${HOSTNAME}
export HUBOT_XMPP_HOST=localhost
export HUBOT_XMPP_PORT=5222
export I18N_WATCH_WORKDIR=.hubot/
export HUDSON="false"
./bin/hubot -n jobot -a xmpp
