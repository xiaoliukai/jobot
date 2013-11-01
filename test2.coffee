# Removes keys specified in second parameter from first parameter
reduce = (a, b) ->
  for propName in b
    delete a[propName]
  a

options={opt:"val1", opt2:"val2", opt3:"val3"}
todelete=['opt', 'opt2']

for key, value of options
  console.log key + "=" + value
  
reduce options, todelete

console.log "-------"
for key, value of options
  console.log key + "=" + value