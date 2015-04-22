_                           = require 'lodash'
logger                      = require('../util/logger').getLogger()
ObservationStoreManager     = require '../store/observationStoreManager'
{OBSERVATION_CATEGORIES}    = require '../util/constants'

# Note: This does not find/handle symbol properties
#       (See https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/getOwnPropertySymbols)
exports.wrapProperties = wrapProperties = (obj, parentTickObj) ->
    wrapped = {}
    storeManager = new ObservationStoreManager(parentTickObj)

    propertyNames = Object.getOwnPropertyNames obj

    _.forEach propertyNames, (propName) ->
        descriptor = Object.getOwnPropertyDescriptor obj, propName

        if descriptor.get?
            logger.warn "The descriptor for the property under key '#{propName}' has a get() function.
                The values that the get() function returns
                will not be wrapped when returned, because they are not part of the object itself."

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
                if ((typeof currentValue is 'object') or (typeof currentValue is 'function')) and !(propStoreManager?) and !(descriptor.get?)
                    logger.debug "Replacing value under key '#{propName}' with a wrapper object"
                    propertyWrapResult = wrapProperties(currentValue, storeManager.getTickObj())
                    propStoreManager = propertyWrapResult.storeManager

                    # This resulted in calls to get() for all properties of `propertyWrapResult.wrapped`
                    # before the call to set() of `wrapped`.
                    # I didn't understand why the extra get() calls occurred, but they disappeared
                    # when I added the `suppressReport` control variable.
                    suppressReport = true
                    currentValue = wrapped[propName] = propertyWrapResult.wrapped
                    suppressReport = false

                    storeManager.addPropertyStore propName, propStoreManager

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
