_                           = require 'lodash'

exports.findMaximumPathLength = (events) ->
    pathFieldWidthEvent = _.max events, (event) ->
        event.pathString.length
    pathFieldWidthEvent.pathString.length

exports.FIELD_NAMES =
    TICK: 'Tick'
    EVENT_CATEGORY: 'Event'
    PATH: 'Path'
    VALUE: '(new) property value'
    COUNT: 'Count'
