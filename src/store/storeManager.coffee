_                           = require 'lodash'
{Promise}                   = require 'es6-promise'
PropertyStore               = require './propertyStore'
CallStore                   = require './callStore'

class StoreManager
    constructor: (parentStoreManager, options={}) ->
        @_tickObj = parentStoreManager?._tickObj ? {tick: 0}
        @_ownStore = new PropertyStore(@_tickObj)
        @_propertiesStoreManagers = {}
        @_callStore = new CallStore(@_tickObj, options)
        # If it was possible to observe changes to the prototype itself,
        # then this should be turned into a list of StoreManager
        # objects (one for each prototype of the object being watched).
        @_prototypeStoreManager = null

    addPropertyStore: (key, storeManager) ->
        @_propertiesStoreManagers[key] = storeManager

    setPrototypeStore: (storeManager) ->
        @_prototypeStoreManager = storeManager

    addOwnObservations: (data) ->
        @_ownStore.add data

    addCallObservation: (data) ->
        @_callStore.add data

    getObservationsPromise: =>
        keys = _.keys @_propertiesStoreManagers
        allPropertyData = Promise.all(_.invoke(@_propertiesStoreManagers, 'getObservationsPromise'))
        allPropertyData.then (contents) =>
            propertyData = _.reduce contents,
                (result, storeData, index) ->
                    result[keys[index]] = storeData
                    return result
                , {}

            remainingPromises = [ @_ownStore.get(), @_callStore.get() ]
            if @_prototypeStoreManager?
                remainingPromises.push @_prototypeStoreManager.getObservationsPromise()
            Promise.all(remainingPromises).then (remainingData) ->
                return {
                    ownData: remainingData[0]
                    callData: remainingData[1]
                    prototypeData: remainingData[2] ? null
                    propertyData
                }

    getObservations: (cb) ->
        @getObservationsPromise().then( (data) ->
            cb null, data
        ).catch( (err) ->
            cb err
        )

module.exports = StoreManager
