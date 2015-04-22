_                           = require 'lodash'
{Promise}                   = require 'es6-promise'
{OBSERVATION_CATEGORIES}    = require '../util/constants'

makeObservationGroup = (parentTickObj) ->
    group = {}

    makeCollection = ->
        collection = {}

        get = ->
            return new Promise((resolve, reject) ->
                contents = _.cloneDeep collection
                resolve(contents)
                )

        add = (data) ->
            toAdd = _.cloneDeep data
            for name, value of toAdd
                collection[name] ?= []
                collection[name].push {
                    tick: parentTickObj.tick
                    value
                }

        return {get, add}

    for name, value of OBSERVATION_CATEGORIES
        group[value] = makeCollection()

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
        for name, value of OBSERVATION_CATEGORIES
            data = groupChanges[value]
            if data?
                group[value].add data
        parentTickObj.tick++

    return {getGroup, addGroup}

class ObservationStore
    constructor: (parentTickObj) ->
        {getGroup: @get, addGroup: @add} = makeObservationGroup(parentTickObj)

module.exports = ObservationStore
