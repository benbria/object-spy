{Promise}                   = require 'es6-promise'
_s                          = require 'underscore.string'
flattenEvents               = require './common/flattenEvents'
sortEvents                  = require './common/sortEvents'
Reporter                    = require './reporter'

class LogStyleReporter extends Reporter
    constructor: ->

    # ```
    # options =
    #     ascendingByTick: [boolean] Sort events ascending or descending by time
    # ```
    _getReportAsStringArray: (data, options) ->
        promise = flattenEvents.observationDataToEventArray data
        promise = promise.then (events) ->
            sortEvents.sortEventsByOrder events, [
                'tick', 'path', 'category'
            ], [
                options.ascendingByTick, true, true
            ]
        promise.then (events) ->
            return new Promise((resolve, reject) ->
                stringEvents = _.map events, (event) ->
                    "#{_s.rpad event.tick, 10} #{_s.rpad event.category, 10}
                     #{event.path.join('.')} value #{event.value}"
                resolve(stringEvents)
            )

module.exports = LogStyleReporter
