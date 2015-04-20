_                           = require 'lodash'
{Promise}                   = require 'es6-promise'
ObservationStore            = require './observationStore'

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

        @getObservationsPromise = getObservationsPromise = ->
            keys = _.keys propertiesStores
            allPropertyData = Promise.all(_.invoke(propertiesStores, 'get'))
            allPropertyData.then (contents) ->
                propertyData = _.reduce contents,
                    (result, storeData, index) ->
                        result[keys[index]] = storeData
                        return result
                    , {}
                ownStore.get().then (ownData) ->
                    return { ownData, propertyData }

        @getObservations = (cb) ->
            getObservationsPromise().then( (data) ->
                cb null, data
            ).catch( (err) ->
                cb err
            )

        @getOwnStore = ->
            ownStore

module.exports = ObservationStoreManager
