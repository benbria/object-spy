_                           = require 'lodash'
{Promise}                   = require 'es6-promise'

# This function just wraps the `lodash` `sortByOrder()` function
# in a promise
exports.sortEventsByOrder = (events, iteratees, orders) ->
    return new Promise((resolve, reject) ->
        sorted = _.sortByOrder events, iteratees, orders
        resolve(sorted)
    )

# Sorts by each element in the path array of an event,
# rather than sorting by path string (produced by joining the array elements).
# (Sorting by the path string would give different results in most cases.)
#
# This function mutates the `events` array
exports.sortEventsByPath = (events, ascending=true) ->
    return new Promise((resolve, reject) ->
        events.sort (eventA, eventB) ->
            pathB = eventB.path
            pathA = eventA.path
            i = 0
            strA = pathA[i]
            strB = pathB[i]
            while strA == strB
                unless strA? and strB?
                    break
                ++i
                strA = pathA[i]
                strB = pathB[i]

            if strA? and strB?
                if strA < strB
                    result = -1
                else
                    result = 1
            else if !(strA?) and !(strB?)
                result = 0
            else if !(strA?)
                result = -1
            else
                result = 1

            unless ascending
                result = -result
            return result

        resolve(events)
    )
