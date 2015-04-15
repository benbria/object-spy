_           = require 'lodash'
{WRAPPED}   = require '../util/constants'
util        = require '../util/util'
logger      = require('../util/logger').getLogger()

# Note: This does not find/handle symbol properties
#       (See https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/getOwnPropertySymbols)
exports.wrapProperties = wrapProperties = (obj) ->
    # Avoid double-wrapping
    if obj[WRAPPED]?
        return obj

    result = {}
    result[WRAPPED] = obj

    propertyNames = Object.getOwnPropertyNames obj

    # Ignore array length
    if _.isArray propertyNames
        propertyNames = _.filter propertyNames, (propName) ->
            propName isnt 'length'

    # Ignore object-spy properties
    propertyNames = _.filter propertyNames, (propName) ->
        !util.isHiddenName(propName)

    _.forEach propertyNames, (propName) ->
        prop = obj[propName]

        if typeof prop is 'function'
            logger.warn "Cannot handle functions yet."
            result[propName] = prop # TODO spy on functions using sinon
        else
            descriptor = Object.getOwnPropertyDescriptor obj, propName

            # Assess whether it is possible to wrap the property
            if descriptor.configurable is false
                error = new Error "Cannot wrap a non-configurable data property."
                logger.error error

            wrapperDescriptor =
                configurable: descriptor.configurable
                enumerable: descriptor.enumerable
                get: ->
                    currentValue = obj[propName]
                    logger.info "get() called for '#{propName}', value is currently #{currentValue}"
                    if typeof currentValue is 'object' and not currentValue[WRAPPED]?
                        result[propName] = wrapProperties(currentValue)
                    return currentValue
                set: (newValue) ->
                    logger.info "set() called for '#{propName}', value is currently #{obj[propName]}"
                    # TODO Avoid loss of usage data when overwriting a wrapped property
                    obj[propName] = newValue

            Object.defineProperty result, propName, wrapperDescriptor

    return result
