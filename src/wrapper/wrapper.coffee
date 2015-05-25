_                           = require 'lodash'
logger                      = require('../util/logger').getLogger()
StoreManager                = require '../store/storeManager'
util                        = require '../util/util'

{PROPERTY_OBSERVATION_CATEGORIES}    = require '../util/constants'

# Note: This does not find/handle symbol properties
#       (See https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/getOwnPropertySymbols)
exports.wrap = wrap = (obj, parentStoreManager=null, options) ->
    storeManager = new StoreManager(parentStoreManager, options)
    wrapped = makeWrapperWithPrototype obj, storeManager, options
    propertyNames = Object.getOwnPropertyNames obj

    _.forEach propertyNames, (propName) ->
        wrapProperty obj, wrapped, propName, storeManager, options

    return {wrapped, storeManager}

makeWrapperWithPrototype = (obj, storeManager, options) ->
    {prototypeWrappingDepth, wrapPropertyPrototypes} = options
    protoObj = Object.getPrototypeOf(obj)

    if protoObj is Function.prototype
        ->
            exceptValue = null
            try
                returnValue = obj.apply this, arguments
            catch exceptValue

            callObservationData = {
                arguments
                exceptValue
                returnValue
            }

            storeManager.addCallObservation callObservationData
            if exceptValue?
                throw exceptValue
            return returnValue

    else
        if protoObj is null or protoObj is Object.prototype
            # Avoid wrapping built-in objects.
            # Another way to do this would perhaps be to check if
            # `_.isNative(protoObj.constructor)` is `true`,
            # but this relies on the accuracy of the `constructor` property,
            # which [isn't guaranteed](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/constructor).
            prototypeWrappingDepth = 0

        if prototypeWrappingDepth isnt 0
            # Recursive case
            if prototypeWrappingDepth > 0
                prototypeWrappingDepth--

            logger.debug "Using a wrapper object as the prototype,
                prototypeWrappingDepth = #{prototypeWrappingDepth}"
            protoObjWrapResult = wrap(
                protoObj, storeManager,
                _.defaults({prototypeWrappingDepth, wrapPropertyPrototypes}, options)
            )
            protoObj = protoObjWrapResult.wrapped
            storeManager.setPrototypeStore protoObjWrapResult.storeManager

        Object.create protoObj

wrapProperty = (obj, wrapped, propName, storeManager, options) ->
    # This prevents attempted redefinition of built-in properties
    # of function objects, which will generate errors.
    # The intention is to remain future-compatible by not hardcoding
    # a list of built-in properties.
    if wrapped[propName]?
        logger.info "
            Skipping wrapping of already-defined property under the key '#{propName}'.
            Using assignment instead."
        wrapped[propName] = obj[propName]
        return wrapped

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

            try
                logger.debug "get() called for '#{propName}', value is currently #{currentValue}"
            catch err
                logger.debug "get() called for '#{propName}'"
            if !isWrapped and wrapOnRetrievalTest(currentValue)
                logger.debug "Replacing value under key '#{propName}' with a wrapper object"
                if options.wrapPropertyPrototypes
                    propertyWrapResult = wrap currentValue, storeManager, options
                else
                    propertyWrapResult = wrap(
                        currentValue, storeManager,
                        _.defaults({prototypeWrappingDepth: 0, wrapPropertyPrototypes: false}, options)
                    )
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
            try
                logger.debug "set() called for '#{propName}', with new value #{newValue}"
            catch err
                logger.debug "set() called for '#{propName}'"
            setValue(newValue)

    try
        Object.defineProperty wrapped, propName, wrapperDescriptor
    catch err
        logger.warn "
            Failed to wrap property '#{propName}', error '#{err}'.
            Using assignment instead."
        wrapped[propName] = obj[propName]

    return wrapped

makeAccessorUtilities = (descriptor, propName) ->
    value = null

    wrapOnRetrievalTest = (currentValue) ->
        false

    if descriptor.get?
        logger.warn "The descriptor for the property under key '#{propName}' has a get() function.
            The values that the get() function returns
            will not be wrapped when returned, because they are not part of the object itself."
        getValue = descriptor.get
        getEventCategory = PROPERTY_OBSERVATION_CATEGORIES.GET
    else if descriptor.set?
        getValue = ->
            logger.debug "get() called for '#{propName}', but property has no getter."
            return undefined
        getEventCategory = PROPERTY_OBSERVATION_CATEGORIES.GET_ATTEMPT
    else
        value = descriptor.value
        getValue = ->
            value
        getEventCategory = PROPERTY_OBSERVATION_CATEGORIES.READ
        wrapOnRetrievalTest = (currentValue) ->
            {isObject} = util.customTypeof currentValue
            isObject

    if descriptor.set?
        setValue = descriptor.set
        setEventCategory = PROPERTY_OBSERVATION_CATEGORIES.SET
    else if descriptor.get?
        setValue = (newValue) ->
            logger.debug "set() called for '#{propName}', but property has no setter."
        setEventCategory = PROPERTY_OBSERVATION_CATEGORIES.SET_ATTEMPT
    else if descriptor.writable
        setValue = (newValue) ->
            value = newValue
        setEventCategory = PROPERTY_OBSERVATION_CATEGORIES.WRITE
    else
        setValue = (newValue) ->
            logger.debug "set() called for '#{propName}', but property is not writable."
        setEventCategory = PROPERTY_OBSERVATION_CATEGORIES.WRITE_ATTEMPT

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
