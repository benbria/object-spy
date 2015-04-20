_                           = require 'lodash'
{Promise}                   = require 'es6-promise'

# This function just wraps the `lodash` `sortByOrder()` function
# in a promise
exports.sortEventsByOrder = (events, iteratees, orders) ->
    return new Promise((resolve, reject) ->
        sorted = _.sortByOrder events, iteratees, orders
        resolve(sorted)
    )
