_                           = require 'lodash'

exports.findMaximumPathLength = (events) ->
    pathFieldWidthEvent = _.max events, (event) ->
        event.pathString.length
    pathFieldWidthEvent.pathString.length
