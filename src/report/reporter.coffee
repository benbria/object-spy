# Class defining the interface of a report output object
class Reporter
    constructor: ->

    # Returns promise which resolves to a single string
    # Parameters
    #   - promise which resolves to the observation data
    #   - `options` depends on the specific type of report
    getReportAsString: (promise, options) ->
        getReportAsStringArray(promise, outputLogger).then (strings) ->
            strings.join("\n")

    # Returns a promise which resolves to an array of individual lines in the report
    # Parameters
    #   - promise which resolves to the observation data
    #   - `options` depends on the specific type of report
    getReportAsStringArray: (promise, options) ->
        promise.then (data) ->
            _getReportAsStringArray data, options

    # To be overridden by derived classes
    _getReportAsStringArray: -> throw new Error("Not implemented")

module.exports = Reporter
