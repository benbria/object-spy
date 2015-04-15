wrapper     = require '../wrapper/wrapper'

# The object wrapper class
class ObjectSpy
    constructor: (obj) ->
        wrapped = wrapper.wrapProperties(obj)
        return wrapped

module.exports = ObjectSpy
