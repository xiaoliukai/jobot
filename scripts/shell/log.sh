#!/bin/sh

# Cleanup logs for jobot.  Keep both the last log and the symlink to it.
if [ -f ".log.conf" ]; then
  source ".log.conf"
fi

cd $BOT_LOG

for i in `/bin/ls`
  do
    if [ "`pwd -P`/$i" != "`readlink $BOT.log`" ] && [ "$i" != "$BOT.log" ]; then
      rm $i
      echo "$i has been deleted"
    fi
  done
