_                           = require 'lodash'

exports.PROPERTY_OBSERVATION_CATEGORIES = PROPERTY_OBSERVATION_CATEGORIES =
    # Not yet implemented
    # To be used to denote the addition of a property
    # ADDED: 'added'

    # Taken into account in `src/store/propertyStore.coffee`,
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

    # Not yet implemented
    # Part of the specification of Object.observe(), but not mentioned in
    # the README of `observe-js` (https://github.com/Polymer/observe-js)
    # RECONFIGURE: 'reconfigured'

exports.PROPERTY_OBSERVATION_CATEGORIES_SORTED =
    _.sortBy PROPERTY_OBSERVATION_CATEGORIES, (name) -> name


exports.CALL_OBSERVATION_CATEGORIES = CALL_OBSERVATION_CATEGORIES =

    # Function call resulting in a value returned
    CALL_RETURN: 'call returned value'

    # Function call generating an exception
    CALL_EXCEPT: 'call threw exception'

exports.CALL_OBSERVATION_CATEGORIES_SORTED =
    _.sortBy CALL_OBSERVATION_CATEGORIES, (name) -> name

# exports.OBJECT_OBSERVATION_CATEGORIES = OBJECT_OBSERVATION_CATEGORIES =

    # Not yet implemented
    # Part of the specification of Object.observe(), but not mentioned in
    # the README of `observe-js` (https://github.com/Polymer/observe-js)
    # SET_PROTOTYPE: 'setPrototype'

    # Not yet implemented
    # Part of the specification of Object.observe(), but not mentioned in
    # the README of `observe-js` (https://github.com/Polymer/observe-js)
    # PREVENT_EXTENSIONS: 'preventExtensions'

# exports.OBJECT_OBSERVATION_CATEGORIES_SORTED =
    # _.sortBy OBJECT_OBSERVATION_CATEGORIES, (name) -> name

exports.ALL_OBSERVATION_CATEGORIES = ALL_OBSERVATION_CATEGORIES = do ->
    _.assign {}, PROPERTY_OBSERVATION_CATEGORIES, CALL_OBSERVATION_CATEGORIES

exports.ALL_OBSERVATION_CATEGORIES_SORTED =
    _.sortBy ALL_OBSERVATION_CATEGORIES, (name) -> name
