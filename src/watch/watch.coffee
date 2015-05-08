wrapper                     = require '../wrapper/wrapper'
logger                      = require('../util/logger').getLogger()
util                        = require '../util/util'
observe                     = require 'object.observe'

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
        # result.unwatch = ->
        #     console.log 'attempting unwatch...'
        #     setTimeout ->
        #         result = Object.unobserve result.wrapped, ->
        #             console.log 'unobserved?'
        #         console.log 'Unobserve returned:'
        #         console.log result
        #     , 500

        return result