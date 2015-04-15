# Helper functions for validating wrapped objects
should                  = require 'should'
_                       = require 'lodash'
srcRequire              = require '../srcRequire'
util                    = srcRequire 'util/util'

# All library-assigned properties should be non-enumerable,
# non-configurable, non-writable, and non-null/undefined
exports.checkPropertyDescriptors = (obj) ->
    propertyNames = Object.getOwnPropertyNames obj
    _.forEach propertyNames, (propName) ->
        if util.isHiddenName propName
            descriptor = Object.getOwnPropertyDescriptor obj, propName
            descriptor.enumerable.should.be.false
            descriptor.configurable.should.be.false
            should.exist descriptor.writable
            descriptor.writable.should.be.false
            should.exist obj[propName]
