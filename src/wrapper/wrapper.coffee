_                           = require 'lodash'
logger                      = require('../util/logger').getLogger()
ObservationStore            = require '../store/observationStore'
ObservationStoreManager     = require '../store/observationStoreManager'
{OBSERVATION_CATEGORIES}    = require '../util/constants'

# Note: This does not find/handle symbol properties
#       (See https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/getOwnPropertySymbols)
exports.wrapProperties = wrapProperties = (originalObj, parentTickObj) ->
    wrapped = {}
    storeManager = new ObservationStoreManager(parentTickObj)

    propertyNames = Object.getOwnPropertyNames obj

    _.forEach propertyNames, (propName) ->
        prop = obj[propName]

        if typeof prop is 'function'
            logger.warn "Cannot wrap functions (yet). Property with key '#{propName}' is a function."
            wrapped[propName] = prop
        else
            descriptor = Object.getOwnPropertyDescriptor obj, propName

            # Assess whether it is possible to wrap the property
            if descriptor.configurable is false
                error = new Error "Cannot wrap non-configurable property, key '#{propName}'."
                logger.error error
                wrapped[propName] = prop

            else
                propStoreManager = null

                wrapperDescriptor =
                    configurable: descriptor.configurable
                    enumerable: descriptor.enumerable

                    get: ->
                        currentValue = obj[propName]

                        observation = {}
                        observation[OBSERVATION_CATEGORIES.ACCESSED] = {}
                        observation[OBSERVATION_CATEGORIES.ACCESSED][propName] = currentValue

                        if propStoreManager?
                            propStoreManager.addOwnObservations observation
                        else
                            storeManager.addOwnObservations observation

                        logger.debug "get() called for '#{propName}', value is currently #{currentValue}"
                        if typeof currentValue is 'object' and not propStoreManager?
                            propertyWrapResult = wrapProperties(currentValue, storeManager.getPropertyTick())
                            propStoreManager = propertyWrapResult.storeManager
                            wrapped[propName] = propertyWrapResult.wrapped
                            storeManager.addPropertyStore propName, propStoreManager.getOwnStore()
                            return propertyWrapResult.wrapped

                        return currentValue

                    set: (newValue) ->
                        observation = {}
                        observation[OBSERVATION_CATEGORIES.CHANGED] = {}
                        observation[OBSERVATION_CATEGORIES.CHANGED][propName] = newValue

                        if propStoreManager?
                            propStoreManager.addOwnObservations observation
                        else
                            storeManager.addOwnObservations observation

                        logger.debug "set() called for '#{propName}', with new value #{newValue}"
                        obj[propName] = newValue

                Object.defineProperty wrapped, propName, wrapperDescriptor

    return {wrapped, storeManager}
