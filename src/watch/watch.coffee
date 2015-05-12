_                           = require 'lodash'
wrapper                     = require '../wrapper/wrapper'
logger                      = require('../util/logger').getLogger()
util                        = require '../util/util'

exports.watch = (obj, options={}) ->
    unless obj?
        logger.warn "watch() called on null or undefined value"
        return null
    else
        type = util.customTypeof obj

        if (type isnt 'object') and (type isnt 'function')
            logger.warn "watch() called on non-object, type '#{type}'"
            return null

        # Validate watch options
        options = _.defaults {}, options, {prototypeWrappingDepth: 0}
        if util.customTypeof(options.prototypeWrappingDepth) isnt 'number'
            logger.warn "watch() received options with invalid type of `prototypeWrappingDepth` property.
                Expected a number."
            return null

        {wrapped, storeManager} = wrapper.wrap obj, null, options.prototypeWrappingDepth
        result = {wrapped}
        result.getObservations = storeManager.getObservations
        result.getObservationsPromise = storeManager.getObservationsPromise
        return result
