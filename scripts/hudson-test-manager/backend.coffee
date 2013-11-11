class HudsonTestManagerBackendSingleton

  instance = null

  @get: () ->
    instance ?= new HudsonTestManagerBackend()

  class HudsonTestManagerBackend
    #TODO Implement

module.exports = HudsonTestManagerBackendSingleton