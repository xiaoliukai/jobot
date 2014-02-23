sort = require 'sorter'.natSort

data =
  "1":
    name: 'com.Alpha'
  "2":
    name: 'com.Tethe'
  "3":
    name: 'com.Beta'
  "4":
    name: '4'

getKeysSortedBy = ( map, sortby ) ->
  return Object.keys( map ).sort ( a, b ) ->
    map[a][sortby] - map[b][sortby];

for key in getKeysSortedBy( data, 'name' )
  console.log key