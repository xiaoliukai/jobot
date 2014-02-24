require "natural-compare-lite"

module.exports.getKeysSortedBy = ( map, sortby ) ->
  return Object.keys( map ).sort ( a, b ) ->
    String.naturalCompare( map[a][sortby], map[b][sortby] )
    
module.exports.getValuesSortedBy = ( map, sortby ) ->
  sortedKeys = module.exports.getKeysSortedBy( map, sortby )
  sortedValues = []
  for key in sortedKeys
    sortedValues.push map[key]
  return sortedValues