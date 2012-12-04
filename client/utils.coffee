exports.pluralize = (number, a, b, c) ->
  if number >= 10 and number <= 20
    return a

  if number == 1 or number % 10 == 1
    return b

  if number <= 4 or number % 10 == 4
    return c

  return a

exports.delay = (ms, func) -> 
  setTimeout func, ms

exports.addCommas = (nStr) ->
  nStr += ''
  x = nStr.split('.')
  x1 = x[0]
  if x.length > 1
    x2 = ('.' + x[1])
  else
    x2 = ''
  rgx = /(\d+)(\d{3})/
  while (rgx.test(x1)) 
    x1 = x1.replace(rgx, '$1' + ' ' + '$2')
  return (x1 + x2)

clone = (obj) ->
  if not obj? or typeof obj isnt 'object'
    return obj

  if obj instanceof Date
    return new Date(obj.getTime()) 

  if obj instanceof RegExp
    flags = ''
    flags += 'g' if obj.global?
    flags += 'i' if obj.ignoreCase?
    flags += 'm' if obj.multiline?
    flags += 'y' if obj.sticky?
    return new RegExp(obj.source, flags) 

  newInstance = new obj.constructor()

  for key of obj
    newInstance[key] = clone obj[key]

  return newInstance

exports.clone = clone