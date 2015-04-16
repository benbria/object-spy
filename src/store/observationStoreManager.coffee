_                       = require 'lodash'
ObservationStore        = require './observationStore'

class ObservationStoreManager
    constructor: ->
        propertyTick = {parentTick: 0}
        ownStore = new ObservationStore(propertyTick)
        propertyTick.parentTick++
        propertiesStores = {}

        @getPropertyTick = ->
            propertyTick.parentTick

        @addPropertyStore = (key, observationStore) ->
            propertiesStores[key] = observationStore
            propertyTick.parentTick++

        @addOwnObservations = (data) ->
            ownStore.add data

        @getObservations = ->
            propertyData = _.reduce propertiesStores,
                (result, store, key) ->
                    result[key] = store.get()
                    return result
                , {}
            return {ownData: ownStore.get(), propertyData }

        @getOwnStore = ->
            ownStore

module.exports = ObservationStoreManager
