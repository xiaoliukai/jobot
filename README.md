Dependencies:
  * Require patched hubot to forward http options and HUBOT_ADAPTER_PATH workaround. See https://github.com/MacKeeper/hubot
  * Require patched scoped-http-client to accept 'rejectUnauthorized: false'. See https://github.com/MacKeeper/node-scoped-http-client

To use forks of ```hubot``` and ```scoped-http-client```:
  * It is highly recommended to git clone dependencies directly in node_modules

Configure IntelliJ:
  * Install coffeescript plugin
  * Run ```coffee -cmw .``` in the root directory
  * To run a ```.coffee``` file, edit the default run configuration for node and check the 'Run with coffeescript plugin'.
    * You will have to set a path to the coffee executable. If not installed, install with ```npm install -g coffee-script``` and the executable should be ```/usr/local/bin/coffee```
  * To debug a ```.coffee``` file
    * Edit the default run configuration for node and *uncheck* the *Run with coffeescript plugin*.
      * On the generated ```.js``` file, run in debug and the ```.coffee``` file breakpoints will trigger.
      * You will have to run:
        * ```coffee -cm node_modules/hubot```
        * ```coffee -cm node_modules/hubot-scripts/src/scripts/file-brain.coffee```
        * ```rm node_modules/hubot-scripts/src/scripts/file-brain.coffee``` the file won't load in debug (see https://github.com/github/hubot/issues/653)
      *Also, make sure there is no ```hubot``` directory in ```node_modules/hubot-xmpp/node_modules``` else messages wont get to the handlers. This is due to two classes with same name loaded but since 
      hubot does an ```instanceof``` on one class but ```hubot-xmpp``` create the other one.  
      * Note: debugging feels a bit experimental. You can also add breakpoints in the .js file
  * Formatter
    * coffeescript, wrapping and braces, 'keep when reformatting', 'line breaks' and 'comment at first column': checked
    * *javascript*, wrapping and braces, 'if statement', 'force braces': do not force (http://stackoverflow.com/questions/16393147/weird-coffeescript-code-style-in-intellij-idea)

