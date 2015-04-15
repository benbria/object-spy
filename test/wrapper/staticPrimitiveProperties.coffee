srcRequire              = require '../srcRequire'
should                  = require 'should'
_                       = require 'lodash'
wrappedValidator        = require '../testHelper/wrappedValidator'
wrapper                 = srcRequire 'wrapper/wrapper'
propertyUtils           = srcRequire 'wrapper/propertyUtils'

# TODO assert all hidden properties are non-enumerable

describe 'Wrapping objects with primitive properties and no property additions or deletions', ->

    it 'should wrap an empty object', ->
        obj = {}
        wrapped = wrapper.wrapProperties(obj)
        wrappedValidator.checkPropertyDescriptors wrapped

        # All properties should be hidden
        propertyNames = Object.getOwnPropertyNames wrapped
        _.forEach propertyNames, (propName) ->
            propertyUtils.isHiddenName(propName).should.be.true
