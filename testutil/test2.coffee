class Brain
  # Represents somewhat persistent storage for the robot. Extend this.
  #
  # Returns a new Brain with no external storage.
  constructor: () ->
    @data =
      users:    { }
      _private: { }

  # Public: Store key-value pair under the private namespace and extend
  # existing @data before emitting the 'loaded' event.
  #
  # Returns the instance for chaining.
  set: (key, value) ->
    if key is Object(key)
      pair = key
    else
      pair = {}
      pair[key] = value

    extend @data._private, pair
    @

  # Public: Get value by key from the private namespace in @data
  # or return null if not found.
  #
  # Returns the value.
  get: (key) ->
    @data._private[key] ? null

  # Public: Remove value by key from the private namespace in @data
  # if it exists
  #
  # Returns the instance for chaining.
  remove: (key) ->
    delete @data._private[key] if @data._private[key]?
    @

# Private: Extend obj with objects passed as additional args.
#
# Returns the original object with updated changes.
extend = (obj, sources...) ->
  for source in sources
    obj[key] = value for own key, value of source
  obj

brain = new Brain

brain.set ""

console.log brain.data