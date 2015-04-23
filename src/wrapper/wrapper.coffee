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
        wrapProperty obj, wrapped, propName, storeManager

    return {wrapped, storeManager}

wrapProperty = (obj, wrapped, propName, storeManager) ->
    descriptor = Object.getOwnPropertyDescriptor obj, propName
    {getValue, setValue} = makeInternalGetterAndSetter descriptor, propName
    propStoreManager = null

    wrapperDescriptor =
        configurable: descriptor.configurable
        enumerable: descriptor.enumerable

        get: ->
            currentValue = getValue()
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
                currentValue = propertyWrapResult.wrapped
                setValue(currentValue)
                storeManager.addPropertyStore propName, propStoreManager

            return currentValue

        set: (newValue) ->
            reportGetSetObservation(
                storeManager,
                OBSERVATION_CATEGORIES.CHANGED,
                propName,
                newValue
            )
            logger.debug "set() called for '#{propName}', with new value #{newValue}"
            setValue(newValue)

    Object.defineProperty wrapped, propName, wrapperDescriptor

makeInternalGetterAndSetter = (descriptor, propName) ->
    value = null

    if descriptor.get?
        logger.warn "The descriptor for the property under key '#{propName}' has a get() function.
            The values that the get() function returns
            will not be wrapped when returned, because they are not part of the object itself."
        getValue = descriptor.get
    else if descriptor.set?
        getValue = ->
            logger.debug "get() called for '#{propName}', but property has no getter."
            return undefined
    else
        value = descriptor.value
        getValue = ->
            value

    if descriptor.set?
        setValue = descriptor.set
    else if descriptor.get?
        setValue = (newValue) ->
            logger.debug "set() called for '#{propName}', but property has no setter."
    else if descriptor.writable
        setValue = (newValue) ->
            value = newValue
    else
        setValue = (newValue) ->
            logger.debug "set() called for '#{propName}', but property is not writable."

    return {getValue, setValue}

reportGetSetObservation = (storeManager, category, key, value) ->
    observation = {}
    shortcut = observation[category] = {}
    shortcut[key] = value
    storeManager.addOwnObservations observation
    return null
