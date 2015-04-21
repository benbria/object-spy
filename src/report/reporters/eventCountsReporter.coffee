{Promise}                   = require 'es6-promise'
_                           = require 'lodash'
flattenEvents               = require '../common/flattenEvents'
sortEvents                  = require '../common/sortEvents'
formatEvents                = require '../common/formatEvents'
Reporter                    = require '../reporter'
constants                   = require '../../util/constants'
{concatenateArrays}         = require '../../util/util'

{OBSERVATION_CATEGORIES, OBSERVATION_CATEGORIES_SORTED} = constants

FIELD_WIDTH = 10

aggregateByEventType = (events) ->
    return new Promise((resolve, reject) ->
        aggregatedEvents = _.reduce OBSERVATION_CATEGORIES,
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
unpackAggregateByEventType = (aggregatedEvents) ->
    promise = Promise.all _.map aggregatedEvents, (events, category) ->
        return new Promise((resolve, reject) ->
            sortedEvents = _.sortBy events, 'index'
            resolve({counts: sortedEvents, category})
        )
    return promise.then (unpackedDisorderedEvents) ->
        nestedArray = _.map OBSERVATION_CATEGORIES_SORTED, (category) ->
            _.find unpackedDisorderedEvents, (value) ->
                value.category is category
        return nestedArray

eventTypeSortedToStringArray = (arrayNestedByEventType, pathFieldWidth) ->
    promise = Promise.all _.map arrayNestedByEventType, (value, index) ->
        return new Promise((resolve, reject) ->
            stringArray = _.map value.counts, ({count, pathString}) ->
                "\t#{_.padRight pathString, pathFieldWidth}#{count}"
            stringArray.unshift "\t#{_.padRight 'Path', pathFieldWidth}Count"
            stringArray.unshift "Event: #{value.category}"
            resolve(stringArray)
        )
    promise.then concatenateArrays

aggregateByPath = (events) ->
    return new Promise((resolve, reject) ->
        aggregatedEvents = _.reduce events,
            (result, event, index) ->
                unless result[event.pathString]?
                    result[event.pathString] = _.reduce OBSERVATION_CATEGORIES,
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

pathSortedToStringArray = (arrayByPath) ->
    promise = Promise.all _.map arrayByPath, (value) ->
        return new Promise((resolve, reject) ->
            stringArray = _.map OBSERVATION_CATEGORIES_SORTED, (category) ->
                "\t#{_.padRight category, FIELD_WIDTH}#{value[category]}"
            stringArray.unshift "\t#{_.padRight 'Event', FIELD_WIDTH}Count"
            stringArray.unshift "Path: #{value.pathString}"
            resolve(stringArray)
        )
    promise.then concatenateArrays

class EventCountsReporter extends Reporter
    constructor: ->

    # ```
    # options =
    #     byEventType: [boolean] Sort events by event type first, then by property path.
    #                  If false, sort by property path, then by event type.
    #                  Default = true
    # ```
    _getReportAsStringArray: (data, options) ->
        options = _.defaults options, {byEventType: true}

        promise = flattenEvents.observationDataToEventArray data
        promise = promise.then sortEvents.sortEventsByPath
        pathFieldWidth = null
        if options.byEventType
            promise = promise.then (events) ->
                return new Promise((resolve, reject) ->
                    pathFieldWidth = formatEvents.findMaximumPathLength(events) + 4
                    resolve(events)
                )

        promise = promise.then (events) ->
            if options.byEventType
                aggregateByEventType events
            else
                aggregateByPath events
        promise = promise.then (aggregatedEvents) ->
            if options.byEventType
                unpackAggregateByEventType aggregatedEvents
            else
                unpackAggregateByPath aggregatedEvents
        promise = promise.then (unpackedEvents) ->
            if options.byEventType
                eventTypeSortedToStringArray unpackedEvents, pathFieldWidth
            else
                pathSortedToStringArray unpackedEvents

module.exports = EventCountsReporter
