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
    for name in loggerMethods
        unless typeof newLogger?[name] is 'function'
            throw new Error "setLogger() called on object missing a '#{name}' function"
    logger = newLogger
