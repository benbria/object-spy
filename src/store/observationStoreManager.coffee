_                           = require 'lodash'
{Promise}                   = require 'es6-promise'
ObservationStore            = require './observationStore'

class ObservationStoreManager
    constructor: (parentTickObj) ->
        @_tickObj = parentTickObj ? {tick: 0}
        @_ownStore = new ObservationStore(@_tickObj)
        @_propertiesStoreManagers = {}

    getTickObj: ->
        @_tickObj

    addPropertyStore: (key, observationStoreManager) ->
        @_propertiesStoreManagers[key] = observationStoreManager

    addOwnObservations: (data) ->
        @_ownStore.add data

    getObservationsPromise: =>
        keys = _.keys @_propertiesStoreManagers
        allPropertyData = Promise.all(_.invoke(@_propertiesStoreManagers, 'getObservationsPromise'))
        allPropertyData.then (contents) =>
            propertyData = _.reduce contents,
                (result, storeData, index) ->
                    result[keys[index]] = storeData
                    return result
                , {}
            @_ownStore.get().then (ownData) ->
                return { ownData, propertyData }

    getObservations: (cb) ->
        @getObservationsPromise().then( (data) ->
            cb null, data
        ).catch( (err) ->
            cb err
        )

module.exports = ObservationStoreManager
