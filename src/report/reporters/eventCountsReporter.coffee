{Promise}                   = require 'es6-promise'
_                           = require 'lodash'
flattenEvents               = require '../common/flattenEvents'
sortEvents                  = require '../common/sortEvents'
textFormatting              = require '../common/textFormatting'
Reporter                    = require '../reporter'
constants                   = require '../../util/constants'
{concatenateArrays}         = require '../../util/util'

{PROPERTY_OBSERVATION_CATEGORIES, PROPERTY_OBSERVATION_CATEGORIES_SORTED} = constants
{EVENT_CATEGORY, PATH, COUNT} = textFormatting.FIELD_NAMES

FIELD_WIDTH = 22

aggregateByEventType = (events) ->
    return new Promise((resolve, reject) ->
        aggregatedEvents = _.reduce PROPERTY_OBSERVATION_CATEGORIES,
            (result, category) ->
                result[category] = {}
                return result
            , {}
        aggregatedEvents = _.reduce events,
            (result, event, index) ->
                result[event.category][event.pathString] ?= {count: 0, index, pathString: event.pathString}
                result[event.category][event.pathString].count++
                return result
            , aggregatedEvents
        resolve(aggregatedEvents)
    )

# Converts results of `aggregateByEventType` to a nested array
# with the proper ordering
unpackAggregateByEventType = (aggregatedEvents, sortByPath, hideZeroCounts) ->
    Promise.all(_.map aggregatedEvents, (events, category) ->
        return new Promise((resolve, reject) ->
            sortedEvents = (if sortByPath
                     _.sortBy events, 'index'
                else
                     _.sortByOrder events, ['count', 'index'], [false, true])
            resolve({counts: sortedEvents, category})
        )
    ).then (unpackedDisorderedEvents) ->
        nestedArray = _.map PROPERTY_OBSERVATION_CATEGORIES_SORTED, (category) ->
            _.find unpackedDisorderedEvents, (value) ->
                value.category is category
        if hideZeroCounts
            nestedArray = _.reject nestedArray, (subObj) ->
                _.isEmpty subObj.counts
        return nestedArray

eventTypeSortedToStringArray = (arrayNestedByEventType, pathFieldWidth) ->
    Promise.all(_.map arrayNestedByEventType, (value, index) ->
        return new Promise((resolve, reject) ->
            stringArray = _.map value.counts, ({count, pathString}) ->
                "\t#{_.padRight pathString, pathFieldWidth}#{count}"
            stringArray.unshift "\t#{_.padRight PATH, pathFieldWidth}#{COUNT}"
            stringArray.unshift "Event: #{value.category}"
            resolve(stringArray)
        )
    ).then concatenateArrays

aggregateByPath = (events) ->
    return new Promise((resolve, reject) ->
        aggregatedEvents = _.reduce events,
            (result, event, index) ->
                unless result[event.pathString]?
                    result[event.pathString] = _.reduce PROPERTY_OBSERVATION_CATEGORIES,
                        (subResult, category) ->
                            subResult[category] = 0
                            return subResult
                        , {index, pathString: event.pathString}
                result[event.pathString][event.category]++
                return result
            , {}
        resolve(aggregatedEvents)
    )

# Converts results of `aggregateByPath` to an array of objects
# with the proper ordering
unpackAggregateByPath = (aggregatedEvents) ->
    promise = new Promise((resolve, reject) ->
        sortedByPath = _.sortBy aggregatedEvents, 'index'
        resolve(sortedByPath)
    )

pathSortedToStringArray = (arrayByPath, hideZeroCounts) ->
    Promise.all(_.map arrayByPath, (value) ->
        return new Promise((resolve, reject) ->
            stringArray = []
            _.forEach PROPERTY_OBSERVATION_CATEGORIES_SORTED, (category) ->
                count = value[category]
                unless hideZeroCounts and count is 0
                    stringArray.push "\t#{_.padRight category, FIELD_WIDTH}#{count}"
            stringArray.unshift "\t#{_.padRight EVENT_CATEGORY, FIELD_WIDTH}#{COUNT}"
            stringArray.unshift "#{PATH}: #{value.pathString}"
            resolve(stringArray)
        )
    ).then concatenateArrays

class EventCountsReporter extends Reporter
    constructor: ->

    # ```
    # options =
    #     byEventType: [boolean] Group events by event type first.
    #                  If false, sort by property path, then group by event type.
    #                  Default = true
    #     byEventTypeAndPath: [boolean] If `byEventType` is `true`, group by event type, then sort by
    #                         count of events (descending), then sort by property path (ascending).
    #                         Otherwise, group by event type, then sort by property path (ascending).
    #                         If `byEventType` is `false`, `byEventTypeAndPath` is ignored.
    #                         Default = true
    #     hideZeroCounts: [boolean] If `byEventType` is `true`, do not output lines for event types
    #                     under which there are no events.
    #                     If `byEventType` is `false`, do not output lines for zero
    #                     counts of events under a given property path.
    #                     Default = true
    # ```
    _getReportAsStringArray: (data, options) ->
        options = _.defaults {}, options, {
            byEventType: true
            byEventTypeAndPath: true
            hideZeroCounts: true
        }
        pathFieldWidth = null

        flattenEvents.observationDataToEventArray(
            data
        ).then(
            sortEvents.sortEventsByPath
        ).then( (events) ->
            if options.byEventType
                return new Promise((resolve, reject) ->
                    pathFieldWidth = textFormatting.findMaximumPathLength(events) + 4
                    resolve(events)
                )
            else
                return events
        ).then( (events) ->
            if options.byEventType
                aggregateByEventType events
            else
                aggregateByPath events
        ).then( (aggregatedEvents) ->
            if options.byEventType
                unpackAggregateByEventType aggregatedEvents, options.byEventTypeAndPath, options.hideZeroCounts
            else
                unpackAggregateByPath aggregatedEvents
        ).then( (unpackedEvents) ->
            if options.byEventType
                eventTypeSortedToStringArray unpackedEvents, pathFieldWidth
            else
                pathSortedToStringArray unpackedEvents, options.hideZeroCounts
        )

module.exports = EventCountsReporter
