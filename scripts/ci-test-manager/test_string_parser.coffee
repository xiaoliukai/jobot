testStringFormat = /^(\s*(\d+|\d+\s*-\s*\d+|[\w\.]+)\s*,?\s*)+$/i

module.exports.parseTestString = ( testString ) ->
  unless testString.match( testStringFormat )
    throw "Cannot parse #{testString}"
  tests = []
  rawtests = testString.split ','
  for rawtest in rawtests
    if rawtest.indexOf( '-' ) != -1
      [from, to] = rawtest.split '-'
      for num in [parseInt( from )..parseInt( to )]
        tests.push num
    else
      tests.push parseInt( rawtest ) || rawtest
  return tests
    