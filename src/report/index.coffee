LogStyleReporter            = require './reporters/logStyleReporter'

module.exports =
    logStyle: ->
        return new LogStyleReporter
