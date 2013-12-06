testStringFormat = /^(\s*(\d+|\d+\s*-\s*\d+|[\w\.]+)\s*,?\s*)+$/i

module.exports.parseTestString = ( testString, callback ) ->
  unless testString.match( testStringFormat )
    callback( "Cannot parse #{testString}" )
  else
    tests = []
    rawtests = testString.split ','
    for rawtest in rawtests
      if rawtest.indexOf( '-' ) != -1
        [from, to] = rawtest.split '-'
        for num in [parseInt( from )..parseInt( to )]
          tests.push num
      else
        tests.push parseInt( rawtest ) || rawtest
    callback null, tests
    