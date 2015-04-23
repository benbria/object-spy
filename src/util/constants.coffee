_                           = require 'lodash'

exports.OBSERVATION_CATEGORIES = OBSERVATION_CATEGORIES =
    ADDED: 'added'
    REMOVED: 'removed'
    GET: 'get'
    GET_ATTEMPT: 'get (no getter)'
    READ: 'read'
    SET: 'set'
    SET_ATTEMPT: 'set (no setter)'
    WRITE: 'write'
    WRITE_ATTEMPT: 'write (not writable)'

exports.OBSERVATION_CATEGORIES_SORTED =
    _.sortBy OBSERVATION_CATEGORIES, (name) -> name
