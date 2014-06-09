#!/bin/sh
export PATH="node_modules/.bin:node_modules/hubot/node_modules/.bin:$PATH"

#export HUBOT_LOG_LEVEL=debug

export JAVA_HOME=/usr/local/jvm/latest7
export M2_HOME=/data/cloud/apache-maven-3.0.3

export PATH=$PATH:$M2_HOME/bin

export rootj=/data/cloud/jobot
export rootj_jobot=$rootj/jobot
export FILE_BRAIN_PATH=$rootj/data
export I18N_WATCH_WORKDIR=$rootj/data/i18nwatch

#CI settings: URL of the service and select the service to be watched.
export HUDSON=false
export HUDSON_TEST_MANAGER_URL='https://hudson.priv.8d.com:8443'
export TEAMCITY_TEST_MANAGER_URL="https://teamcity.priv.8d.com:8443"

# Set path to adapter since we are using npm link for hubot dependency. See Readme
export HUBOT_ADAPTER_PATH=`pwd`/node_modules/

# Warning values :
export HUDSON_TEST_MANAGER_ASSIGNMENT_TIMEOUT_IN_MINUTES=15             #15
export HUDSON_TEST_MANAGER_DEFAULT_FIX_THRESHOLD_ESCALADE_HOURS=24      #24
export HUDSON_TEST_MANAGER_DEFAULT_FIX_THRESHOLD_WARNING_HOURS=96       #96

# export HUBOT_XMPP_PASSWORD=XXXXXXXXXXXXXXX
. $rootj/config


# ${HUBOT_XMPP_PASSWORD:?"Need to set HUBOT_XMPP_PASSWORD: export HUBOT_XMPP_PASSWORD=..."}
# if [ -z "$HUBOT_XMPP_PASSWORD" ]; then
#     read -p "Jabber password:" HUBOT_XMPP_PASSWORD
#     export HUBOT_XMPP_PASSWORD=$HUBOT_XMPP_PASSWORD
#     echo $HUBOT_XMPP_PASSWORD
# fi

# Jabber connection :
export HUBOT_XMPP_CONFERENCE_DOMAINS=conference.jabber.8d.com
export HUBOT_XMPP_USERNAME=jobot@jabber.8d.com
#export HUBOT_XMPP_ROOMS=jobottest@conference.jabber.8d.com
export HUBOT_XMPP_ROOMS=backoffice@conference.jabber.8d.com
export HUBOT_XMPP_HOST=jabber.8d.com
export HUBOT_XMPP_PORT=5222

cd  $root_jobot

exec bin/hubot -n jobot -a xmpp
