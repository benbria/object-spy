wrapper                     = require '../wrapper/wrapper'
logger                      = require('../util/logger').getLogger()

exports.watch = (obj) ->
    unless obj?
        logger.warn "watch() called on null or undefined value"
        return null
    else if (typeof obj isnt 'object') and (typeof obj isnt 'function')
        logger.warn "watch() called on non-object, type '#{typeof obj}'"
        return null

    {wrapped, storeManager} = wrapper.wrapProperties obj, null
    result = {wrapped}
    result.getObservations = storeManager.getObservations
    result.getObservationsPromise = storeManager.getObservationsPromise
    return result
