srcRequire              = require '../srcRequire'
expect                  = require('chai').expect
_                       = require 'lodash'
wrapper                 = srcRequire 'wrapper/wrapper'

describe 'Wrapping objects with primitive properties and no property additions or deletions', ->

    it 'should wrap an empty object', ->
        obj = {}
        {wrapped} = wrapper.wrapProperties(obj)
        expect(wrapped).to.be.empty
        expect(wrapped).to.be.instanceof(Object)
