#!/bin/sh
export PATH="node_modules/.bin:node_modules/hubot/node_modules/.bin:$PATH"

#export HUBOT_LOG_LEVEL=debug

export JAVA_HOME=/usr/local/jvm/latest7
export M2_HOME=/data/cloud/apache-maven-3.0.3

export PATH=$PATH:$M2_HOME/bin

export FILE_BRAIN_PATH=/data/cloud/jobot
export HUDSON_TEST_MANAGER_URL='https://hudson.priv.8d.com:8443'
export I18N_WATCH_WORKDIR='/data/cloud/jobot/i18nwatch'

# Set path to adapter since we are using npm link for hubot dependency. See Readme
export HUBOT_ADAPTER_PATH=`pwd`/node_modules/

#need  HUDSON set to true to use hudson_connection, false to use teamcity_connect
export HUDSON=false
#need TEAMCITY_TEST_MANAGER_URL=https://teamcity...
# ${HUBOT_XMPP_PASSWORD:?"Need to set HUBOT_XMPP_PASSWORD: export HUBOT_XMPP_PASSWORD=..."}
if [ -z "$HUBOT_XMPP_PASSWORD" ]; then
    read -p "Jabber password:" HUBOT_XMPP_PASSWORD
    export HUBOT_XMPP_PASSWORD=$HUBOT_XMPP_PASSWORD
    echo $HUBOT_XMPP_PASSWORD
fi

export HUBOT_XMPP_CONFERENCE_DOMAINS=conference.jabber.8d.com
export HUBOT_XMPP_USERNAME=jobot@jabber.8d.com
export HUBOT_XMPP_ROOMS=jobottest@conference.jabber.8d.com,backoffice@conference.jabber.8d.com
export HUBOT_XMPP_HOST=jabber.8d.com
export HUBOT_XMPP_PORT=5222

./bin/hubot -n jobot -a xmpp
