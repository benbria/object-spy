_                           = require 'lodash'
wrapper                     = require '../wrapper/wrapper'
logger                      = require('../util/logger').getLogger()
util                        = require '../util/util'

exports.watch = (obj, options={}) ->
    unless obj?
        logger.warn "watch() called on null or undefined value"
        return null
    else
        {type, isObject} = util.customTypeof obj

        unless isObject
            logger.warn "watch() called on non-object, type '#{type}'"
            return null

        # Validate watch options
        options = prepareOptions options
        unless options?
            return null

        {wrapped, storeManager} = wrapper.wrap obj, null, options.prototypeWrappingDepth
        result = {wrapped}
        result.getObservations = storeManager.getObservations
        result.getObservationsPromise = storeManager.getObservationsPromise
        return result

prepareOptions = (options) ->
    # Validate watch options
    options = _.defaults {}, options, {
        prototypeWrappingDepth: 0
        propertyPrototypeWrappingDepth: 0
    }

    valid = true

    if util.customTypeof(options.prototypeWrappingDepth).type isnt 'number'
        logger.warn "watch() received options with invalid type of `prototypeWrappingDepth` property.
            Expected a number."
        valid = false
    else if Math.floor(options.prototypeWrappingDepth) isnt options.prototypeWrappingDepth
        logger.warn "watch() received options with non-integer `prototypeWrappingDepth` property."
        valid = false

    if util.customTypeof(options.propertyPrototypeWrappingDepth).type isnt 'number'
        logger.warn "watch() received options with invalid type of `propertyPrototypeWrappingDepth` property.
            Expected a number."
        valid = false
    else if Math.floor(options.propertyPrototypeWrappingDepth) isnt options.propertyPrototypeWrappingDepth
        logger.warn "watch() received options with non-integer `propertyPrototypeWrappingDepth` property."
        valid = false

    if valid
        return options
    else
        return null
