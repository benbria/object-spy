_                           = require 'lodash'
logger                      = require('../util/logger').getLogger()
ObservationStoreManager     = require '../store/observationStoreManager'
{OBSERVATION_CATEGORIES}    = require '../util/constants'
util                        = require '../util/util'

# Note: This does not find/handle symbol properties
#       (See https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/getOwnPropertySymbols)
exports.wrap = wrap = (obj, parentStoreManager=null, prototypeWrappingDepth=0) ->
    storeManager = new ObservationStoreManager(parentStoreManager)
    wrapped = makeWrapperWithPrototype obj, storeManager, prototypeWrappingDepth
    propertyNames = Object.getOwnPropertyNames obj

    _.forEach propertyNames, (propName) ->
        wrapProperty obj, wrapped, propName, storeManager

    return {wrapped, storeManager}

makeWrapperWithPrototype = (obj, storeManager, prototypeWrappingDepth) ->
    protoObj = Object.getPrototypeOf(obj)
    if protoObj is null or protoObj is Object.prototype or protoObj is Function.prototype
        prototypeWrappingDepth = 0

    if prototypeWrappingDepth isnt 0
        # Recursive case
        if prototypeWrappingDepth > 0
            prototypeWrappingDepth--

        logger.debug "Using a wrapper object as the prototype, prototypeWrappingDepth = #{prototypeWrappingDepth}"
        protoObjWrapResult = wrap protoObj, storeManager, prototypeWrappingDepth
        protoObj = protoObjWrapResult.wrapped
        storeManager.setPrototypeStore protoObjWrapResult.storeManager

    Object.create protoObj

wrapProperty = (obj, wrapped, propName, storeManager) ->
    descriptor = Object.getOwnPropertyDescriptor obj, propName
    {
        getValue
        setValue
        wrapOnRetrievalTest
        getEventCategory
        setEventCategory
    } = makeAccessorUtilities descriptor, propName
    isWrapped = null

    wrapperDescriptor =
        configurable: descriptor.configurable
        enumerable: descriptor.enumerable

        get: ->
            currentValue = getValue()
            reportGetSetObservation(
                storeManager,
                getEventCategory,
                propName,
                currentValue
            )

            logger.debug "get() called for '#{propName}', value is currently #{currentValue}"
            if !isWrapped and wrapOnRetrievalTest(currentValue)
                logger.debug "Replacing value under key '#{propName}' with a wrapper object"
                propertyWrapResult = wrap currentValue, storeManager, 0
                isWrapped = true
                currentValue = propertyWrapResult.wrapped
                setValue(currentValue)
                storeManager.addPropertyStore propName, propertyWrapResult.storeManager

            return currentValue

        set: (newValue) ->
            reportGetSetObservation(
                storeManager,
                setEventCategory,
                propName,
                newValue
            )
            logger.debug "set() called for '#{propName}', with new value #{newValue}"
            setValue(newValue)

    Object.defineProperty wrapped, propName, wrapperDescriptor

makeAccessorUtilities = (descriptor, propName) ->
    value = null

    wrapOnRetrievalTest = (currentValue) ->
        false

    if descriptor.get?
        logger.warn "The descriptor for the property under key '#{propName}' has a get() function.
            The values that the get() function returns
            will not be wrapped when returned, because they are not part of the object itself."
        getValue = descriptor.get
        getEventCategory = OBSERVATION_CATEGORIES.GET
    else if descriptor.set?
        getValue = ->
            logger.debug "get() called for '#{propName}', but property has no getter."
            return undefined
        getEventCategory = OBSERVATION_CATEGORIES.GET_ATTEMPT
    else
        value = descriptor.value
        getValue = ->
            value
        getEventCategory = OBSERVATION_CATEGORIES.READ
        wrapOnRetrievalTest = (currentValue) ->
            {isObject} = util.customTypeof currentValue
            isObject

    if descriptor.set?
        setValue = descriptor.set
        setEventCategory = OBSERVATION_CATEGORIES.SET
    else if descriptor.get?
        setValue = (newValue) ->
            logger.debug "set() called for '#{propName}', but property has no setter."
        setEventCategory = OBSERVATION_CATEGORIES.SET_ATTEMPT
    else if descriptor.writable
        setValue = (newValue) ->
            value = newValue
        setEventCategory = OBSERVATION_CATEGORIES.WRITE
    else
        setValue = (newValue) ->
            logger.debug "set() called for '#{propName}', but property is not writable."
        setEventCategory = OBSERVATION_CATEGORIES.WRITE_ATTEMPT

    return {
        getValue
        setValue
        wrapOnRetrievalTest
        getEventCategory
        setEventCategory
    }

reportGetSetObservation = (storeManager, category, key, value) ->
    observation = {}
    shortcut = observation[category] = {}
    shortcut[key] = value
    storeManager.addOwnObservations observation
    return null
