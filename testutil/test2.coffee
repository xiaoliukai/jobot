
previousTestFail = {}
previousTestFail['test1'] =
  a: "allo"
previousTestFail['test2'] =
  a: "toi"

for test, value of previousTestFail
  console.log "#{test} is #{value}"