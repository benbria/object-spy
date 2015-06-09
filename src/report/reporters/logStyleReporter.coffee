{Promise}                   = require 'es6-promise'
_                           = require 'lodash'
util                        = require '../../util/util'
flattenEvents               = require '../common/flattenEvents'
sortEvents                  = require '../common/sortEvents'
textFormatting              = require '../common/textFormatting'
Reporter                    = require '../reporter'

LARGE_FIELD_WIDTH = 22
SMALL_FIELD_WIDTH = 12
{TICK, EVENT_CATEGORY, PATH, VALUE_TYPE, VALUE_VALUE, VALUE_OR_CALL} = textFormatting.FIELD_NAMES

class LogStyleReporter extends Reporter
    constructor: ->

    # ```
    # options =
    #     ascendingByTick: [boolean] Sort events ascending or descending by time
    #                      Default = true
    #     showArguments: [boolean] Show arguments as part of function call events
    #                    Default = true
    #     showCallObjectValues: [boolean] Obtain string versions of function call argument values
    #                           (if `showArguments` is also true)
    #                           and return values that are objects. Otherwise, display only
    #                           values that are primitive types.
    #                           Note that object values may not be available, depending
    #                           on the options passed to `watch()` in `src/watch/watch.coffee`
    #                           Default = false
    # ```
    _getReportAsStringArray: (data, options) ->
        options = _.defaults {}, options, {
            ascendingByTick: true
            showArguments: true
            showCallObjectValues: false
        }
        pathFieldWidth = null

        flattenEvents.observationDataToEventArray(
            data
        ).then( (events) ->
            sortEvents.sortEventsByOrder events, [
                'tick', 'path', 'category'
            ], [
                options.ascendingByTick, true, true
            ]
        ).then( (events) ->
            return new Promise((resolve, reject) ->
                pathFieldWidth = textFormatting.findMaximumPathLength(events) + 4
                resolve(events)
            )
        ).then( (events) =>
            return new Promise((resolve, reject) =>
                stringEvents = _.map events, (event) =>
                    @_eventToString event, pathFieldWidth, options
                stringEvents.unshift "#{_.padRight TICK, SMALL_FIELD_WIDTH}\
                    #{_.padRight EVENT_CATEGORY, LARGE_FIELD_WIDTH}\
                    #{_.padRight PATH, pathFieldWidth}\
                    #{_.padRight VALUE_TYPE, SMALL_FIELD_WIDTH}\
                    #{if options.showArguments then VALUE_OR_CALL else VALUE_VALUE}"
                resolve(stringEvents)
            )
        )

    _eventToString: (event, pathFieldWidth, options) ->
        stringEvent = "#{_.padRight event.tick, SMALL_FIELD_WIDTH}\
        #{_.padRight event.category, LARGE_FIELD_WIDTH}\
        #{_.padRight event.pathString, pathFieldWidth}\
        #{_.padRight event.value.type, SMALL_FIELD_WIDTH}"

        if event.arguments?
            if options.showArguments
                argumentsStrings = _.map event.arguments, (arg) ->
                    if arg.valueIsStored
                        {isObject} = util.customTypeof arg.value
                        if options.showCallObjectValues || !isObject
                            return JSON.stringify(arg.value)
                    arg.type
                stringEvent += "(#{argumentsStrings.join(', ')}) -> "
            if event.value.valueIsStored
                {isObject} = util.customTypeof event.value.value
                if options.showCallObjectValues || !isObject
                    stringEvent += "#{JSON.stringify(event.value.value)}"
                else
                    stringEvent += event.value.type
            else
                stringEvent += event.value.type

        else if event.value.valueIsStored
            stringEvent += "#{event.value.value}"

        return stringEvent

module.exports = LogStyleReporter
