_                           = require 'lodash'
{Promise}                   = require 'es6-promise'

exports.concatenateArrays = (arrays) ->
    return new Promise((resolve, reject) ->
        allArray = _.reduce arrays,
            (result, value) ->
                result.push value...
                return result
            , []
        resolve(allArray)
    )

# To be maintained in parallel with `isComplexTypeString`
exports.customTypeof = (value) ->
    unless _.isNull(value)
        type = typeof value
        if type is 'number' and _.isNaN(value)
            type = 'NaN'
        else if _.isArray(value)
            type = 'array'
        else if _.isRegExp(value)
            type = 'regexp'
    else
        type = 'null'

    return {type, isObject: _.isObject(value)}

# To be maintained in parallel with `customTypeof`
exports.isComplexTypeString = (type) ->
    type in ['object', 'function', 'array', 'regexp']
