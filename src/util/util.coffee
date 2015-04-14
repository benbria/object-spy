{LIBNAME}   = require './constants'
LIBNAME_LENGTH = LIBNAME.length

exports.getHiddenName = (name) ->
    return "#{LIBNAME}#{name}"

exports.isHiddenName = isHiddenName = (name) ->
    return name.search LIBNAME is 0

exports.getUnhiddenName = (hiddenName) ->
    if isHiddenName hiddenName
        return hiddenName.substring LIBNAME.length
    return null
