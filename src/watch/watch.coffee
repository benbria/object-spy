wrapper                     = require '../wrapper/wrapper'
logger                      = require('../util/logger').getLogger()
util                        = require '../util/util'

exports.watch = (obj) ->
    unless obj?
        logger.warn "watch() called on null or undefined value"
        return null
    else
        type = util.customTypeof obj

        if (type isnt 'object') and (type isnt 'function')
            logger.warn "watch() called on non-object, type '#{type}'"
            return null

        {wrapped, storeManager} = wrapper.wrapProperties obj, null
        result = {wrapped}
        result.getObservations = storeManager.getObservations
        result.getObservationsPromise = storeManager.getObservationsPromise
        return result
