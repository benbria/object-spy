_                           = require 'lodash'
logger                      = require('../util/logger').getLogger()
ObservationStore            = require '../store/observationStore'
ObservationStoreManager     = require '../store/observationStoreManager'
{OBSERVATION_CATEGORIES}    = require '../util/constants'

# Note: This does not find/handle symbol properties
#       (See https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/getOwnPropertySymbols)
exports.wrapProperties = wrapProperties = (obj, parentTickObj) ->
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
            # This is probably a little stricter than necessary - Could do a more fine-grained check.
            if descriptor.configurable is false
                error = new Error "Cannot wrap non-configurable property, key '#{propName}'."
                logger.error error
                wrapped[propName] = prop

            else
                propStoreManager = null
                suppressReport = false

                wrapperDescriptor =
                    configurable: descriptor.configurable
                    enumerable: descriptor.enumerable

                    get: ->
                        currentValue = obj[propName]
                        unless suppressReport
                            reportGetSetObservation(
                                storeManager,
                                OBSERVATION_CATEGORIES.ACCESSED,
                                propName,
                                currentValue
                            )

                        logger.debug "get() called for '#{propName}', value is currently #{currentValue}"
                        if typeof currentValue is 'object' and not propStoreManager?
                            propertyWrapResult = wrapProperties(currentValue, storeManager.getPropertyTick())
                            propStoreManager = propertyWrapResult.storeManager

                            # This resulted in calls to get() for all properties of `propertyWrapResult.wrapped`
                            # before the call to set() of `wrapped`.
                            # I didn't understand why the extra get() calls occurred, but they disappeared
                            # when I added the `suppressReport` control variable.
                            suppressReport = true
                            wrapped[propName] = propertyWrapResult.wrapped
                            suppressReport = false

                            storeManager.addPropertyStore propName, propStoreManager.getOwnStore()
                            return propertyWrapResult.wrapped

                        return currentValue

                    set: (newValue) ->
                        unless suppressReport
                            reportGetSetObservation(
                                storeManager,
                                OBSERVATION_CATEGORIES.CHANGED,
                                propName,
                                newValue
                            )
                        logger.debug "set() called for '#{propName}', with new value #{newValue}"
                        obj[propName] = newValue

                Object.defineProperty wrapped, propName, wrapperDescriptor

    return {wrapped, storeManager}

reportGetSetObservation = (storeManager, category, key, value) ->
    observation = {}
    shortcut = observation[category] = {}
    shortcut[key] = value
    storeManager.addOwnObservations observation
    return null
