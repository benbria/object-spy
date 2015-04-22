LogStyleReporter            = require './reporters/logStyleReporter'
EventCountsReporter         = require './reporters/eventCountsReporter'

module.exports =
    logStyle: ->
        return new LogStyleReporter
    eventCounts: ->
        return new EventCountsReporter
