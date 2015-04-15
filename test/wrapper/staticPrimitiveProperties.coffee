srcRequire              = require '../srcRequire'
should                  = require 'should'
_                       = require 'lodash'
wrappedValidator        = require '../testHelper/wrappedValidator'
wrapper                 = srcRequire 'wrapper/wrapper'
util                    = srcRequire 'util/util'

# TODO assert all hidden properties are non-enumerable

describe 'Wrapping objects with primitive properties and no property additions or deletions', ->

    it 'should wrap an empty object', ->
        obj = {}
        wrapped = wrapper.wrapProperties(obj)
        wrappedValidator.checkPropertyDescriptors wrapped

        # All properties should be hidden
        propertyNames = Object.getOwnPropertyNames wrapped
        _.forEach propertyNames, (propName) ->
            util.isHiddenName(propName).should.be.true
