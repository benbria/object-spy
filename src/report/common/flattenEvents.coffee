_                           = require 'lodash'
{Promise}                   = require 'es6-promise'

labelEventArray = (events, key, path) ->
    return new Promise((resolve, reject) ->
            labelledEvents = _.map events, (event) ->
                labelledEvent = _.assign {}, event
                labelledEvent.path = []
                labelledEvent.path.unshift key, path...
                return labelledEvent
            resolve(labelledEvents)
        )

concatenateArrays = (arrays) ->
    return new Promise((resolve, reject) ->
        allArray = _.reduce arrays,
            (result, value) ->
                result.push value...
                return result
            , []
        resolve(allArray)
    )

flattenCategoryData = (categoryData, path) ->
    allPromise = Promise.all _.map(categoryData, (value, key) ->
        labelEventArray value, key, path
    )
    allPromise.then concatenateArrays

flattenObservationStoreData = (observationData, path) ->
    allPromise = Promise.all _.map(observationData, (value) ->
        flattenCategoryData value, path
    )
    allPromise = allPromise.then concatenateArrays

flattenObservationStoreManagerData = (observationData, path) ->
    promises = _.map observationData.propertyData, (value, key) ->
        if value.ownData?
            flattenObservationStoreManagerData value, path.concat([key])
        else
            flattenObservationStoreData value, path.concat([key])
    promises.push flattenObservationStoreData(observationData.ownData, path)
    Promise.all promises

# Converts observation store data
# into a promise which resolves to an array of events
# The original data is not modified
observationDataToEventArray = (data) ->
    flattenObservationStoreManagerData data, []
