wrapper     = require '../wrapper/wrapper'

# The object wrapper class
class ObjectSpy
    constructor: (obj) ->
        this = wrapper.wrapProperties(obj)
