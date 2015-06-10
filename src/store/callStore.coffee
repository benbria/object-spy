_                               = require 'lodash'
serialize                       = require 'serialize-javascript'
{Promise}                       = require 'es6-promise'
{CALL_OBSERVATION_CATEGORIES}   = require '../util/constants'
util                            = require '../util/util'
logger                      = require('../util/logger').getLogger()

class CallStore
    constructor: (@_parentTickObj, options={}) ->
        @_copyCallObjectValues = options.copyCallObjectValues ? false
        @_callReturns = []
        @_callExcepts = []

    get: ->
        allContents = Promise.all(_.map([@_callReturns, @_callExcepts],
            (list) ->
                return new Promise((resolve, reject) ->
                    listCopy = _.cloneDeep list
                    resolve(listCopy)
                )
            )
        )
        allContents.then (contents) ->
            result = {}
            result[CALL_OBSERVATION_CATEGORIES.CALL_RETURN] = contents[0] ? []
            result[CALL_OBSERVATION_CATEGORIES.CALL_EXCEPT] = contents[1] ? []
            return result

    add: (data) ->
        if data.returnValue? and !data.exceptValue?
            @_addCallReturn data
        else if data.exceptValue? and !data.returnValue?
            @_addCallExcept data
        else
            logger.error "Unknown type of call event passed to CallStore.add()"

    _addCallReturn: (data) ->
        event =
            tick: @_parentTickObj.tick++
            arguments: @_copyArguments(data.arguments)
            value: @_copyValue(data.returnValue)

        @_callReturns.push event


    _addCallExcept: (data) ->
        event =
            tick: @_parentTickObj.tick++
            arguments: @_copyArguments(data.arguments)
            value: @_copyValue(data.exceptValue)

        @_callExcepts.push event

    _copyArguments: (args) ->
        _.map args, (arg) =>
            @_copyValue(arg)

    _copyValue: (value) ->
        {isObject, type} = util.customTypeof value
        copy =
            type: type
            valueIsStored: (@_copyCallObjectValues || !isObject)
        if copy.valueIsStored
            copy.value = serialize(value)
        return copy

module.exports = CallStore
