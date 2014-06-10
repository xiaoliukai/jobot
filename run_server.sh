#!/bin/sh

#export HUBOT_LOG_LEVEL=debug

export JAVA_HOME=/usr/local/jvm/latest7
export M2_HOME=/data/cloud/apache-maven-jobot
export PATH="$rootj_jobot/node_modules/.bin:$rootj_jobot/node_modules/hubot/node_modules/.bin:$PATH"
export PATH=$PATH:$M2_HOME/bin:$JAVA_HOME:/usr/local/bin

export rootj=/data/cloud/jobot
export rootj_jobot=$rootj/jobot
export FILE_BRAIN_PATH=$rootj/data
export I18N_WATCH_WORKDIR=$rootj/data/i18nwatch
export JOBOT_LOG=$rootj/log

#CI settings: URL of the service and select the service to be watched.
export HUDSON=false

# Set path to adapter since we are using npm link for hubot dependency. See Readme
export HUBOT_ADAPTER_PATH=$rootj_jobot/node_modules/

# Warning values :
export HUDSON_TEST_MANAGER_ASSIGNMENT_TIMEOUT_IN_MINUTES=15             #15
export HUDSON_TEST_MANAGER_DEFAULT_FIX_THRESHOLD_ESCALADE_HOURS=24      #24
export HUDSON_TEST_MANAGER_DEFAULT_FIX_THRESHOLD_WARNING_HOURS=96       #96

# export HUBOT_XMPP_PASSWORD=XXXXXXXXXXXXXXX
# export JABBER_DOMAIN=XXXXXXXXXXXXX
# export HUDSON_TEST_MANAGER_URL='https://url:port'
# export TEAMCITY_TEST_MANAGER_URL="https://url:port"

. $rootj/data/config

# Jabber connection :

export HUBOT_XMPP_CONFERENCE_DOMAINS=conference.$JABBER_DOMAIN
export HUBOT_XMPP_USERNAME=jobot@$JABBER_DOMAIN
#export HUBOT_XMPP_ROOMS=jobottest@conference.$JABBER_DOMAIN
export HUBOT_XMPP_ROOMS=backoffice@conference.$JABBER_DOMAIN
export HUBOT_XMPP_HOST=$JABBER_DOMAIN
export HUBOT_XMPP_PORT=5222

cd  $rootj_jobot

exec bin/hubot -n jobot -a xmpp >> $JOBOT_LOG/jobot.log 2>&1
