util                        = require '../util/util'

loggerMethods = [
    "debug", "info", "warn", "error"
]

logger = do ->
    result = {}
    for name in loggerMethods
        if name is "debug"
            result[name] = console.log
        else
            result[name] = console[name]
    return result

exports.getLogger = ->
    result = {}
    for name in loggerMethods
        do (name) ->
            result[name] = ->
                logger[name].apply null, arguments
    return result

exports.setLogger = (newLogger) ->
    validateLogger newLogger
    logger = newLogger

validateLogger = (newLogger) ->
    unless newLogger?
        throw new Error "validateLogger() called on a null or undefined value"
    for name in loggerMethods
        unless util.customTypeof(newLogger?[name]).type is 'function'
            throw new Error "validateLogger() called on object missing a '#{name}' function"
