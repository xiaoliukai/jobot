#!/bin/sh
HOSTNAME=`hostname`

export HUBOT_LOG_LEVEL=debug
coffee -cm .
export HUDSON_TEST_MANAGER_DEFAULT_FIX_THRESHOLD_WARNING_HOURS=24
export HUDSON_TEST_MANAGER_URL="https://hudson.priv.8d.com:8443"
# Set path to adapter since we are using npm link for hubot dependency. See Readme
#export TEAMCITY_TEST_MANAGER_URL="https://teamcity.priv.8d.com:8443"
export TEAMCITY_TEST_MANAGER_URL="http://localhost:8111"
export HUBOT_ADAPTER_PATH=`pwd`/node_modules/
export FILE_BRAIN_PATH=.
export HUBOT_XMPP_USERNAME=hubot@${HOSTNAME}
export HUBOT_XMPP_CONFERENCE_DOMAINS=conference.${HOSTNAME}
export HUBOT_XMPP_PASSWORD=hubot
export HUBOT_XMPP_ROOMS=deploy@conference.${HOSTNAME}
export HUBOT_XMPP_HOST=localhost
export HUBOT_XMPP_PORT=5222
export I18N_WATCH_WORKDIR=.hubot/
export HUDSON="false"
export HUDSON_TEST_MANAGER_ASSIGNMENT_TIMEOUT_IN_MINUTES=15
./bin/hubot -n jobot -a xmpp
