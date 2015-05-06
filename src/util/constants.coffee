_                           = require 'lodash'

exports.OBSERVATION_CATEGORIES = OBSERVATION_CATEGORIES =
    # Not yet implemented
    # To be used to denote the addition of a property
    # ADDED: 'added'
    #
    # Taken into account in `src/store/observationStore.coffee`,
    # but not yet implemented in wrapper code.
    REMOVED: 'removed'
    # Call to an accessor property's `get()`` function
    GET: 'get'
    # Attempted call to an undefined `get()` function of an accessor property
    GET_ATTEMPT: 'get (no getter)'
    # Retrieval of the value of a data property
    READ: 'read'
    # Call to an accessor property's `set()` function
    SET: 'set'
    # Attempted call to an undefined `set()` function of an accessor property
    SET_ATTEMPT: 'set (no setter)'
    # Write to the value of a data property
    WRITE: 'write'
    # Attempt to write to a data property that is not writable
    WRITE_ATTEMPT: 'write (not writable)'
    #
    # Not yet implemented
    # Part of the specification of Object.observe(), but not mentioned in
    # the README of `observe-js` (https://github.com/Polymer/observe-js)
    # RECONFIGURE: 'reconfigured'
    #
    # Not yet implemented
    # Part of the specification of Object.observe(), but not mentioned in
    # the README of `observe-js` (https://github.com/Polymer/observe-js)
    # SET_PROTOTYPE: 'setPrototype'
    #
    # Not yet implemented
    # Part of the specification of Object.observe(), but not mentioned in
    # the README of `observe-js` (https://github.com/Polymer/observe-js)
    # PREVENT_EXTENSIONS: 'preventExtensions'

exports.OBSERVATION_CATEGORIES_SORTED =
    _.sortBy OBSERVATION_CATEGORIES, (name) -> name
