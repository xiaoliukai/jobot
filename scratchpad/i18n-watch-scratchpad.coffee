fs = require 'fs'

I18nWatcher = require( '../scripts/i18n-watch' )

rootworkdir = '/tmp/i18n'
fs.mkdirSync rootworkdir unless fs.existsSync rootworkdir

info =
  giturl: 'ssh://git@git.priv.8d.com:58676/ftk'
  branch: 'feature/bike/fix-subscription-startdate'
  workdir: '123'
  lastknowncommit: '10599d4bb88ccb108082094febe3f9f0e176674b'

#info =
#  giturl: 'https://github.com/MacKeeper/testi18nwatch.git'
#  branch: 'master'
#  workdir: '456'

storage = {}

robot =
  respond: () ->
  brain:
    get: () ->
      return storage

i18n = new I18nWatcher( robot, true )

#i18n.cloneRepo info, ( err, hash ) ->
#  if err
#    console.log "Failed: #{err}"
#  else
#    console.log "Last hash: #{hash}"

i18n.processProject info, ( err, info ) ->
  if err
    console.log "Failed: #{err}"
  else
    console.log "Info: #{info}"

# jobot Watch translations on git repo ssh://git@git.priv.8d.com:58676/ftk branch feature/bike/fix-subscription-startdate and broadcast to room deploy@conference.manuel-darveaus-imac.local