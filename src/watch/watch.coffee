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

        options = prepareOptions options
        unless options?
            return null

        {wrapped, storeManager} = wrapper.wrap obj, null, options
        result = {wrapped}
        result.getObservations = storeManager.getObservations
        result.getObservationsPromise = storeManager.getObservationsPromise
        return result

# Validate watch options
prepareOptions = (options) ->
    options = _.defaults {}, options, {
        prototypeWrappingDepth: 0
        wrapPropertyPrototypes: false
    }

    valid = true

    if util.customTypeof(options.prototypeWrappingDepth).type isnt 'number'
        logger.warn "watch() received options with invalid type of `prototypeWrappingDepth` property.
            Expected a number."
        valid = false
    else if Math.floor(options.prototypeWrappingDepth) isnt options.prototypeWrappingDepth
        logger.warn "watch() received options with non-integer `prototypeWrappingDepth` property."
        valid = false
    else if options.prototypeWrappingDepth < -1
        logger.warn "watch() received options with `prototypeWrappingDepth` property less than -1."
        valid = false

    if util.customTypeof(options.wrapPropertyPrototypes).type isnt 'boolean'
        logger.warn "watch() received options with invalid type of `wrapPropertyPrototypes` property.
            Expected a boolean."
        valid = false

    if options.prototypeWrappingDepth is 0 and options.wrapPropertyPrototypes
        logger.warn "watch() received options where `wrapPropertyPrototypes` is true,
            but `prototypeWrappingDepth` is zero.
            The two settings are in conflict."
        valid = false

    if valid
        return options
    else
        logger.warn "Aborting watch() operation due to invalid options object."
        return null
