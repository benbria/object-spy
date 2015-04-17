_                           = require 'lodash'
{OBSERVATION_CATEGORIES}    = require '../util/constants'

makeObservationGroup = (parentTickObj) ->
    group = {}
    microTick = 0
    macroTick = 0

    makeCollection = ->
        collection = {}

        get = ->
            return _.cloneDeep collection

        add = (data) ->
            toAdd = _.cloneDeep data
            for name, value of toAdd
                collection[name] ?= []
                collection[name].push {
                    microTick
                    macroTick
                    parentTick: parentTickObj.parentTick
                    value
                }
                ++microTick

        return {get, add}

    for name, value of OBSERVATION_CATEGORIES
        group[value] = makeCollection()

    getGroup = ->
        groupData = _.reduce group,
            (result, value, key) ->
                result[key] = value.get()
                return result
            , {}

    addGroup = (groupChanges) ->
        for name, value of OBSERVATION_CATEGORIES
            data = groupChanges[value]
            if data?
                group[value].add data
        ++macroTick

    return {getGroup, addGroup}

class ObservationStore
    constructor: (parentTickObj) ->
        {getGroup: @get, addGroup: @add} = makeObservationGroup(parentTickObj)

module.exports = ObservationStore
