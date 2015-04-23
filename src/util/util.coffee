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

exports.customTypeof = (value) ->
    if value isnt null
        typeof value
    else
        'null'
