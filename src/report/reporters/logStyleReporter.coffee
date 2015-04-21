{Promise}                   = require 'es6-promise'
_                           = require 'lodash'
flattenEvents               = require '../common/flattenEvents'
sortEvents                  = require '../common/sortEvents'
textFormatting              = require '../common/textFormatting'
Reporter                    = require '../reporter'

FIELD_WIDTH = 10
{TICK, EVENT_CATEGORY, PATH, VALUE} = textFormatting.FIELD_NAMES

class LogStyleReporter extends Reporter
    constructor: ->

    # ```
    # options =
    #     ascendingByTick: [boolean] Sort events ascending or descending by time
    #                      Default = true
    # ```
    _getReportAsStringArray: (data, options) ->
        options = _.defaults options, {ascendingByTick: true}

        promise = flattenEvents.observationDataToEventArray data
        promise = promise.then (events) ->
            sortEvents.sortEventsByOrder events, [
                'tick', 'path', 'category'
            ], [
                options.ascendingByTick, true, true
            ]

        pathFieldWidth = null
        promise = promise.then (events) ->
            return new Promise((resolve, reject) ->
                pathFieldWidth = textFormatting.findMaximumPathLength(events) + 4
                resolve(events)
            )

        promise.then (events) ->
            return new Promise((resolve, reject) ->
                stringEvents = _.map events, (event) ->
                    "#{_.padRight event.tick, FIELD_WIDTH}#{_.padRight event.category, FIELD_WIDTH}
                     #{_.padRight event.pathString, pathFieldWidth}#{event.value}"
                stringEvents.unshift "#{_.padRight TICK, FIELD_WIDTH}#{_.padRight EVENT_CATEGORY, FIELD_WIDTH}
                 #{_.padRight PATH, pathFieldWidth}#{VALUE}"
                resolve(stringEvents)
            )

module.exports = LogStyleReporter
