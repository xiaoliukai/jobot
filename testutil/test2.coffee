moment = require('moment')

date1 = moment()
date2 = moment().add(3, 'day').add(6, 'hours')

status = "#{date1.diff(date2, 'days', true)}"

console.log status