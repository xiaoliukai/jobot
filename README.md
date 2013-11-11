Dependencies:
  * Require patched hubot to forward http options and HUBOT_ADAPTER_PATH workaround. See https://github.com/MacKeeper/hubot
  * Require patched scoped-http-client to accept 'rejectUnauthorized: false'. See https://github.com/MacKeeper/node-scoped-http-client
  * Require redis. Install from http://redis.io/ and run redis-server
  * Require

To use forks of 'hubot' and 'scoped-http-client':
  * In 'hubot' and 'node-scoped-http-client' repo, run 'npm link'
  * In 'jobot' repo, run 'npm link hubot' and 'npm link scoped-http-client'
  * Because of the way nope find dependencies, hubot won't be able to find the hubot-xmpp adapter. node lookup directories for dependencies but fails big time with symlink (which npm link creates)
    * Environment variable HUBOT_ADAPTER_PATH is set in the launchers to workaround this

Configure IntelliJ:
  * Install coffeescript plugin
  * Install File watcher plugin
  * To run a .coffee file, edit the default run configuration for node and check the 'Run with coffeescript plugin'.
    * You will have to set a path to the coffee executable. If not installed, install with 'npm install -g coffeescript' and the executable should be '/usr/local/bin/coffee'
  * To debug a .coffee file
    * In Projects Settings, File Watcher, add a coffeescript file watcher (_coffeescript_ *not* coffeescript source map)
      * Uncheck 'Immediate file synchronization'
      * Arguments should be '--compile --map $FileName$'
      * Output paths should be '$FileNameWithoutExtension$.js:$FileNameWithoutExtension$.map'
    * Edit the default run configuration for node and *uncheck* the 'Run with coffeescript plugin'.
      * On the generated .js file, run in debug and the .coffee file breakpoints will trigger.
      * Note: debugging feels a bit experimental. You can also add breakpoints in the .js file


