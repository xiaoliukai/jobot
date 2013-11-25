regex = ///
        (?:what|which).+?(appserver|system)?.*version.*\son\s(\w*).*
        ///i

results = "What appserver version is installed on production server?".match regex
results[0..].forEach ( match ) ->
  console.log match

  
expectedMatches = ['appserver', 'production']
for match, index in results[1..]
  console.log match
  console.log expectedMatches[index]