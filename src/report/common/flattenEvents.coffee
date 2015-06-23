_                           = require 'lodash'
{Promise}                   = require 'es6-promise'
{concatenateArrays}         = require '../../util/util'

labelEventArray = (events, key, path, category) ->
    return new Promise((resolve, reject) ->
            labelledEvents = _.map events, (event) ->
                labelledEvent = _.assign {}, event
                labelledEvent.path = path.slice()
                if key?
                    labelledEvent.path.push key
                labelledEvent.pathString = ".#{labelledEvent.path.join('.')}"
                labelledEvent.category = category
                return labelledEvent
            resolve(labelledEvents)
        )

flattenCategoryData = (categoryData, path, categoryName) ->
    Promise.all(_.map(categoryData, (value, key) ->
        labelEventArray value, key, path, categoryName
    )).then concatenateArrays

flattenObservationStoreData = (observationData, path) ->
    Promise.all(_.map(observationData, (value, categoryName) ->
        flattenCategoryData value, path, categoryName
    )).then concatenateArrays

flattenCallStoreData = (observationData, path) ->
    Promise.all(_.map(observationData, (value, categoryName) ->
        labelEventArray value, null, path, categoryName
    )).then concatenateArrays

flattenObservationStoreManagerData = (observationData, path) ->
    promises = _.map observationData.propertyData, (value, key) ->
        if value.ownData?
            # Recursive case
            flattenObservationStoreManagerData value, path.concat([key])
        else
            # Base case
            flattenObservationStoreData value, path.concat([key])
    promises.push flattenObservationStoreData(observationData.ownData, path)
    promises.push flattenCallStoreData(observationData.callData, path)
    if observationData.prototypeData?
        promises.push(
            flattenObservationStoreManagerData(
                observationData.prototypeData, path.concat(['__proto__'])
                )
            )
    Promise.all(promises).then concatenateArrays

# Converts observation store data
# into a promise which resolves to an array of events
# The original data is not modified
exports.observationDataToEventArray = (data) ->
    flattenObservationStoreManagerData data, []
