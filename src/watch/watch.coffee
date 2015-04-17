wrapper     = require '../wrapper/wrapper'

exports.watch = (obj) ->
    {wrapped, storeManager} = wrapper.wrapProperties obj, null
    result = {wrapped}
    result.getObservations = storeManager.getObservations
    return result
