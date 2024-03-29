_                           = require 'lodash'
serialize                   = require 'serialize-javascript'
{Promise}                   = require 'es6-promise'
{PROPERTY_OBSERVATION_CATEGORIES}    = require '../util/constants'
util                        = require '../util/util'

makeObservationGroup = (parentTickObj) ->
    group = {}

    makeCollection = (categoryName) ->
        collection = {}

        get = ->
            return new Promise((resolve, reject) ->
                contents = _.cloneDeep collection
                resolve(contents)
            )

        add = (data) ->
            for name, value of data
                {type} = util.customTypeof value
                valueWrapper = {type}
                valueWrapper.valueIsStored = shouldStoreValue(categoryName, value)
                if valueWrapper.valueIsStored
                    valueWrapper.value = serialize(value)
                collection[name] ?= []
                collection[name].push {
                    tick: parentTickObj.tick
                    value: valueWrapper
                }

        return {get, add}

    for name, value of PROPERTY_OBSERVATION_CATEGORIES
        group[value] = makeCollection(value)

    getGroup = ->
        keys = _.keys group
        allContents = Promise.all _.invoke(group, 'get')
        allContents.then (contents) ->
            _.reduce contents,
                (result, value, index) ->
                    result[keys[index]] = value
                    return result
                , {}

    addGroup = (groupChanges) ->
        for name, value of PROPERTY_OBSERVATION_CATEGORIES
            data = groupChanges[value]
            if data?
                group[value].add data
        parentTickObj.tick++

    return {getGroup, addGroup}

# This function prevents calls to wrapper accessor functions
# that result in additional observations.
shouldStoreValue = (category, value) ->
    unless (category is PROPERTY_OBSERVATION_CATEGORIES.REMOVED) or (category is PROPERTY_OBSERVATION_CATEGORIES.READ)
        true
    else
        {isObject} = util.customTypeof value
        !isObject

class PropertyStore
    constructor: (parentTickObj) ->
        {getGroup: @get, addGroup: @add} = makeObservationGroup(parentTickObj)

module.exports = PropertyStore
