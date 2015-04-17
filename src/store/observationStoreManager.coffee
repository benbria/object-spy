_                       = require 'lodash'
ObservationStore        = require './observationStore'

class ObservationStoreManager
    constructor: (parentTickObj) ->
        tickObj = parentTickObj ? {tick: 0}
        ownStore = new ObservationStore(tickObj)
        propertiesStores = {}

        @getTickObj = ->
            tickObj

        @addPropertyStore = (key, observationStore) ->
            propertiesStores[key] = observationStore

        @addOwnObservations = (data) ->
            ownStore.add data

        @getObservations = ->
            propertyData = _.reduce propertiesStores,
                (result, store, key) ->
                    result[key] = store.get()
                    return result
                , {}
            return { ownData: ownStore.get(), propertyData }

        @getOwnStore = ->
            ownStore

module.exports = ObservationStoreManager
