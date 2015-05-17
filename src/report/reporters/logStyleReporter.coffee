{Promise}                   = require 'es6-promise'
_                           = require 'lodash'
flattenEvents               = require '../common/flattenEvents'
sortEvents                  = require '../common/sortEvents'
textFormatting              = require '../common/textFormatting'
Reporter                    = require '../reporter'

LARGE_FIELD_WIDTH = 22
SMALL_FIELD_WIDTH = 12
{TICK, EVENT_CATEGORY, PATH, VALUE_TYPE, VALUE_VALUE} = textFormatting.FIELD_NAMES

class LogStyleReporter extends Reporter
    constructor: ->

    # ```
    # options =
    #     ascendingByTick: [boolean] Sort events ascending or descending by time
    #                      Default = true
    # ```
    _getReportAsStringArray: (data, options) ->
        options = _.defaults {}, options, {ascendingByTick: true}
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
        ).then( (events) ->
            return new Promise((resolve, reject) ->
                stringEvents = _.map events, (event) ->
                    stringEvent = "#{_.padRight event.tick, SMALL_FIELD_WIDTH}\
                    #{_.padRight event.category, LARGE_FIELD_WIDTH}\
                    #{_.padRight event.pathString, pathFieldWidth}\
                    #{_.padRight event.value.type, SMALL_FIELD_WIDTH}"
                    if event.value.valueIsStored
                        stringEvent += "#{event.value.value}"
                    return stringEvent
                stringEvents.unshift "#{_.padRight TICK, SMALL_FIELD_WIDTH}\
                    #{_.padRight EVENT_CATEGORY, LARGE_FIELD_WIDTH}\
                    #{_.padRight PATH, pathFieldWidth}\
                    #{_.padRight VALUE_TYPE, SMALL_FIELD_WIDTH}\
                    #{VALUE_VALUE}"
                resolve(stringEvents)
            )
        )

module.exports = LogStyleReporter
