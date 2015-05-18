_                           = require 'lodash'
{Promise}                   = require 'es6-promise'
ObservationStore            = require './observationStore'

class ObservationStoreManager
    constructor: (parentStoreManager) ->
        @_tickObj = parentStoreManager?._tickObj ? {tick: 0}
        @_ownStore = new ObservationStore(@_tickObj)
        @_propertiesStoreManagers = {}
        # If it was possible to observe changes to the prototype itself,
        # then this should be turned into a list of ObservationStoreManager
        # objects (one for each prototype of the object being watched).
        @_prototypeStoreManager = null

    addPropertyStore: (key, observationStoreManager) ->
        @_propertiesStoreManagers[key] = observationStoreManager

    setPrototypeStore: (observationStoreManager) ->
        @_prototypeStoreManager = observationStoreManager

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

            remainingPromises = [ @_ownStore.get() ]
            if @_prototypeStoreManager?
                remainingPromises.push @_prototypeStoreManager.getObservationsPromise()
            Promise.all(remainingPromises).then (remainingData) ->
                return {
                    ownData: remainingData[0]
                    prototypeData: remainingData[1] ? null
                    propertyData
                }

    getObservations: (cb) ->
        @getObservationsPromise().then( (data) ->
            cb null, data
        ).catch( (err) ->
            cb err
        )

module.exports = ObservationStoreManager
