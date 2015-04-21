_                           = require 'lodash'

exports.OBSERVATION_CATEGORIES = OBSERVATION_CATEGORIES =
    ADDED: 'added'
    REMOVED: 'removed'
    CHANGED: 'changed'
    ACCESSED: 'accessed'

exports.OBSERVATION_CATEGORIES_SORTED =
    _.sortBy OBSERVATION_CATEGORIES, (name) -> name
