_                           = require 'lodash'

exports.findMaximumPathLength = (events) ->
    pathFieldWidthEvent = _.max events, (event) ->
        event.pathString.length

    pathFieldWidthEvent?.pathString?.length ? 0

exports.FIELD_NAMES =
    TICK: 'Tick'
    EVENT_CATEGORY: 'Event'
    PATH: 'Path'
    VALUE_TYPE: 'Value type'
    VALUE_VALUE: 'new/return value (if stored)'
    VALUE_OR_CALL: '(new) value (if stored), or arguments -> return value'
    COUNT: 'Count'
