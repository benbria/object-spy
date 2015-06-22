# object-spy

Discover how code is using an object by sending it a spy instead.
In the process, find out what the object looks like to its clients.

## Suggested uses

#### Assisting with documentation

Determine the format of input data expected by some component.

(Output data can be analyzed as well, but with many limitations
until [this issue](../../issues/8) is addressed.)

#### Mocking objects

Run the code to be tested with a spy object,
and check what properties of the spy were used,
in order to quickly write mock object literals in test code.

#### Discovering dead code

Determine how much of an object is actually ever accessed.

(This is possible by inspection currently, but
the intention is to provide an automated tool, as described
[here](../../issues/16).)

#### Investigating performance issues

Count the number of times that the various properties
of an object are used by client code and assess,
for example, if the paths of frequently used properties
are overly long.

## Usage

```CoffeeScript
# require() the interface
objectSpy = require 'object-spy'

# If desired, provide your own logger
# (especially useful for suppressing debug output).
# The default logger is the console, as set
# in `src/util/logger.coffee`
logger =
    debug: ->
    info: (msg) -> console.error "objectSpy info: #{msg}"
    warn: (msg) -> console.warn "objectSpy warning: #{msg}"
    error: (msg) -> console.error "objectSpy error: #{msg}"

objectSpy.setLogger logger

# You have an object that is built through the action
# of several functions, and you don't know exactly
# which parts of it are important.
prototype = { notOwnProperty: 2 }
obj = Object.create prototype
obj.referer = "Mispelt"
obj.referrer = "Not quite a duplicate"
obj.magicNumber = NaN
obj.subObj =
        none: null
obj.triple = (x) -> x * 3

descriptor =
    configurable: true
    enumerable: false
    value: "Mispelt"
    writable: false

Object.defineProperty obj.subObj, 'referer', descriptor

# The object gets used in some procedure, the internals
# of which are difficult to trace
processObj = (obj) ->
    # Spy objects return spies for non-primitive properties
    subObj = obj.subObj
    obj.magicNumber = obj.magicNumber
    obj.magicNumber = subObj.none
    # Spying on functions results in many 'info' and 'warn'
    # messages because built-in function properties cannot be wrapped.
    # Rather than hardcode a list of built-in properties to avoid wrapping,
    # the library attempts to wrap all properties and logs when
    # it doesn't work. This behaviour was chosen in order
    # to be more future-proof.
    obj.magicNumber += obj.triple(obj.notOwnProperty)
    console.log "Got message from referrer: %s", subObj.referer

# Prepare a spy object
# (this is destructuring assignment syntax)
{wrapped: spy, getObservationsPromise} = objectSpy.watch obj, {
    prototypeWrappingDepth: -1
    # Note that this leaves other options with default values
}
# Find out how the object is used directly
processObj spy

# There is also a `getObservations` method
# which takes a callback, instead of returning a promise.
promisedData = getObservationsPromise()

# Format usage data as a table of sequential events
logStyleReporter = objectSpy.reporters.logStyle()
logStyleReporter.getReportAsString(promisedData).then( (report) ->
    console.log "Log-style report:"
    console.log report, '\n'
)

# Aggregate usage data by property path and type of event
eventCountsReporter = objectSpy.reporters.eventCounts()
eventCountsReporter.getReportAsString(promisedData).then( (report) ->
    console.log "Event counts report:"
    console.log report, '\n'
)

# More 'reporters' may be available in the future.
# Check `src/report/index.coffee` for the full list.
```

The output of the above passage is:

```
objectSpy info: Skipping wrapping of already-defined property under the key 'length'. Using assignment instead.
objectSpy info: Skipping wrapping of already-defined property under the key 'name'. Using assignment instead.
objectSpy warning: Failed to wrap property 'arguments', error 'TypeError: Cannot redefine property: arguments'. Using assignment instead.
objectSpy warning: Failed to wrap property 'caller', error 'TypeError: Cannot redefine property: caller'. Using assignment instead.
objectSpy info: Skipping wrapping of already-defined property under the key 'prototype'. Using assignment instead.
Got message from referrer: Mispelt
Log-style report:
Tick        Event                 Path                         (new) value, or arguments -> return value
0           read                  .subObj                      object
1           read                  .magicNumber                 null
2           write                 .magicNumber                 null
3           read                  .subObj.none                 null
4           write                 .magicNumber                 null
5           read                  .magicNumber                 null
6           read                  .__proto__.notOwnProperty    2
7           read                  .triple                      function
8           call returned value   .triple                      (2) -> 6
9           write                 .magicNumber                 6
10          read                  .subObj.referer              "Mispelt"

Event counts report:
Event: call returned value
	Path                         Count
	.triple                      1
Event: read
	Path                         Count
	.__proto__.notOwnProperty    1
	.magicNumber                 2
	.subObj                      1
	.subObj.none                 1
	.subObj.referer              1
	.triple                      1
Event: write
	Path                         Count
	.magicNumber                 3
```

## Public interface (`src/index.coffee`)

#### `reporters.XXX()`
Returns an instance of the class of reporter
corresponding to the short name `XXX`.

#### `setLogger(newLogger)`
Redirects the logging output to the `newLogger` object,
provided that the object has all methods listed in `src/util/logger.coffee`.
Otherwise, throws an exception.

Note that the logging is global to the library,
and is not customizable on a per-spy basis.

#### `watch(obj, options={})`
Returns an object with the following properties
- `wrapped`: A spy which can be substituted in client code
  for the `obj` argument, to collect usage data.
- `getObservations(cb)`: Calls the callback `cb` with `err` and `data` arguments,
  where `data` is the set of observations collected from `wrapped` to date.
- `getObservationsPromise()`: Returns a promise with the same effect as
  `getObservations()`

##### `options` parameter to `watch()`
- `prototypeWrappingDepth`: An integer indicating the depth to which
  the object's prototype chain should be watched. (Default: `0`)
  - `-1`: Watch all members of the prototype chain until encountering
    `Object.prototype` or `Function.prototype`
  - `0`: Don't watch the object's prototype
  - `n`, where `n > 0`: Watch the last `n` members
    of the prototype chain.
- `wrapPropertyPrototypes`: If `true`, watch the prototypes of the
  object's properties the prototypes of the properties of the object's prototype,
  and so forth. (i.e. Watch the prototypes of every
  non-primitive value in the structure.) (Default: `false`)
  - The depth to which these additional prototype chains are
    watched is set by the `prototypeWrappingDepth` value.
    If `prototypeWrappingDepth` is zero, and `wrapPropertyPrototypes` is true,
    `watch()` will log a warning and do nothing.
- `copyCallObjectValues`: If `true`, the values of non-primitive arguments
  and return values of the wrapped object's methods are stored
  for later reporting. Otherwise, only primitive values,
  and the types, but not the values, of non-primitive values are stored.
  (Default: `false`)

## Limitations

The following caveats are not covered by GitHub [issues](../../issues),
but arise from design decisions.

#### Objects can be wrapped multiple times

The library does not check if an object is already a spy before
constructing a spy for it. In order to prevent property name conflicts,
there are no hidden properties stored in a spy object
that indicate that it is a spy.

#### Circular references are not detected

Spy objects provide access to spies rather than return
non-primitive properties of objects directly to the client code.
While spies will check if a given property has already been accessed,
to avoid wrapping its value again, they will not check if an object
has previously been accessed via a different property path
before wrapping it.

Given that values are lazily-wrapped, circular references
do not result in stack overflows. However, they will result in bugs
such as the following:

```CoffeeScript
objectSpy = require 'object-spy'

obj = {}
obj.obj = obj

console.log "obj.obj == obj: ", obj.obj == obj # True

{wrapped: spy} = objectSpy.watch obj

console.log "spy.obj == spy: ", spy.obj == spy # False
```

As circular references are probably quite rare,
the performance impact of checking for them was thought
to be unwarranted.

#### Spies cannot observe existing bindings

Any references to the original object's properties that were created
before the spy object circumvent the wrapper code
and are therefore unobservable.
This includes methods of an object that change the object's state.

A partial solution for this problem would be to use a library providing
an enhanced version of
[`Object.observe()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/observe)
to recursively track changes to the entire object. Unfortunately, `Object.observe()`
does not report property accesses; It only outputs changes.

#### Some changes/events are not observed

The list of events which are currently reported is located
in [`constants.coffee`](./src/util/constants.coffee).

Some notable absences from the list are the following:
- Accesses to the prototype: The library can report
  accesses and changes to the properties of an object's prototype
  (refer to the above description of the options
  that can be passed to `watch()` for details).
  However, it cannot record accesses to the prototype itself.
  For example, uses of the `__proto__` property,
  and `Object.getPrototypeOf()` will not result in observations.

#### Spy objects have accessor properties instead of data properties

If client code relies on the distinction between properties with data descriptors
and properties with accessor descriptors (see [MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/defineProperty)
for more information on what these are), then the spy object will
behave differently than the original object.

In other words, the client code will know it is a spy,
and observations made through the spy will be useless.

## Further reading

Visit the [wiki](../../wiki)
