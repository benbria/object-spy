{Promise}                   = require 'es6-promise'
_                           = require 'lodash'
flattenEvents               = require '../common/flattenEvents'
sortEvents                  = require '../common/sortEvents'
Reporter                    = require '../reporter'

FIELD_WIDTH = 10

class LogStyleReporter extends Reporter
    constructor: ->

    # ```
    # options =
    #     ascendingByTick: [boolean] Sort events ascending or descending by time
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
                pathFieldWidthEvent = _.max events, (event) ->
                    event.pathString.length
                pathFieldWidth = pathFieldWidthEvent.pathString.length + 4
                resolve(events)
            )
        promise.then (events) ->
            return new Promise((resolve, reject) ->
                stringEvents = _.map events, (event) ->
                    "#{_.padRight event.tick, FIELD_WIDTH}#{_.padRight event.category, FIELD_WIDTH}
                     #{_.padRight event.pathString, pathFieldWidth}= #{event.value}"
                stringEvents.unshift "#{_.padRight 'Tick', FIELD_WIDTH}#{_.padRight 'Event', FIELD_WIDTH}
                 #{_.padRight 'Path', pathFieldWidth}  (new) property value"
                resolve(stringEvents)
            )

module.exports = LogStyleReporter
