{LIBNAME, WRAPPED_HIDDEN_NAME}   = require '../util/constants'
LIBNAME_LENGTH = LIBNAME.length

exports.getHiddenName = getHiddenName = (name) ->
    return "#{LIBNAME}#{name}"

exports.isHiddenName = isHiddenName = (name) ->
    return name.search(LIBNAME) is 0

exports.getUnhiddenName = (hiddenName) ->
    if isHiddenName hiddenName
        return hiddenName.substring LIBNAME.length
    return null

exports.isWrapped = (obj) ->
    obj[WRAPPED_HIDDEN_NAME]?

exports.defineHiddenValueProperty = (unhiddenName, value, obj) ->
    Object.defineProperty(obj, getHiddenName(unhiddenName), {
        enumerable: false,
        configurable: false,
        writable: false,
        value: value
    })
