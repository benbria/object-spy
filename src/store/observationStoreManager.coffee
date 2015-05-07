_                           = require 'lodash'
{Promise}                   = require 'es6-promise'
ObservationStore            = require './observationStore'

class ObservationStoreManager
    constructor: (parentTickObj) ->
        @tickObj = parentTickObj ? {tick: 0}
        @ownStore = new ObservationStore(@tickObj)
        @propertiesStoreManagers = {}

    getTickObj: ->
        @tickObj

    addPropertyStore: (key, observationStoreManager) ->
        @propertiesStoreManagers[key] = observationStoreManager

    addOwnObservations: (data) ->
        @ownStore.add data

    getObservationsPromise: =>
        keys = _.keys @propertiesStoreManagers
        allPropertyData = Promise.all(_.invoke(@propertiesStoreManagers, 'getObservationsPromise'))
        allPropertyData.then (contents) =>
            propertyData = _.reduce contents,
                (result, storeData, index) ->
                    result[keys[index]] = storeData
                    return result
                , {}
            @ownStore.get().then (ownData) ->
                return { ownData, propertyData }

    getObservations: (cb) ->
        @getObservationsPromise().then( (data) ->
            cb null, data
        ).catch( (err) ->
            cb err
        )

module.exports = ObservationStoreManager
