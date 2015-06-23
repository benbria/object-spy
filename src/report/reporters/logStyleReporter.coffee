{Promise}                   = require 'es6-promise'
_                           = require 'lodash'
util                        = require '../../util/util'
flattenEvents               = require '../common/flattenEvents'
sortEvents                  = require '../common/sortEvents'
textFormatting              = require '../common/textFormatting'
Reporter                    = require '../reporter'

LARGE_FIELD_WIDTH = 22
SMALL_FIELD_WIDTH = 12
{TICK, EVENT_CATEGORY, PATH, VALUE_VALUE, VALUE_OR_CALL} = textFormatting.FIELD_NAMES

class LogStyleReporter extends Reporter
    constructor: ->

    # ```
    # options =
    #     ascendingByTick: [boolean] Sort events ascending or descending by time
    #                      Default = true
    #
    #     showArguments: [string]
    #                    'off' = Do not show arguments as part of function call events
    #                    'short' = Show argument lists, but output types for
    #                              non-primitive arguments rather than values.
    #                    'long' = Show argument lists, including string
    #                             representations of arguments that are
    #                             non-primitive values.
    #
    #                    Default = 'short'
    #
    #                    Note that non-primitive values may not be available,
    #                    depending on the options passed to `watch()`
    #                    in `src/watch/watch.coffee`.
    #
    #     showObjectValues: [boolean] Output string versions of non-primitive
    #                       values (including function call return values).
    #
    #                       If `false`, the types of values will be output
    #                       instead of the values themselves.
    #
    #                       If a non-primitive value is not stored
    #                       (see `shouldStoreValue()` in `src/store/propertyStore.coffee`),
    #                       the type of the value is output regardless.
    #
    #                       Default = false
    # ```
    _getReportAsStringArray: (data, options) ->
        options = _.defaults {}, options, {
            ascendingByTick: true
            showArguments: 'short'
            showObjectValues: false
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
                    #{if options.showArguments isnt 'off' then VALUE_OR_CALL else VALUE_VALUE}"
                resolve(stringEvents)
            )
        )

    _eventToString: (event, pathFieldWidth, options) ->
        stringEvent = "#{_.padRight event.tick, SMALL_FIELD_WIDTH}\
        #{_.padRight event.category, LARGE_FIELD_WIDTH}\
        #{_.padRight event.pathString, pathFieldWidth}"

        if event.arguments? and (options.showArguments isnt 'off')
            argumentsStrings = _.map event.arguments, (arg) ->
                if arg.valueIsStored
                    isObject = util.isComplexTypeString arg.type
                    if options.showArguments is 'long' or !isObject
                        return arg.value
                arg.type
            stringEvent += "(#{argumentsStrings.join(', ')}) -> "

        printValue = false
        if event.value.valueIsStored
            isObject = util.isComplexTypeString event.value.type
            printValue = !isObject or options.showObjectValues

        if printValue
            stringEvent += "#{event.value.value}"
        else
            stringEvent += event.value.type

        return stringEvent

module.exports = LogStyleReporter
