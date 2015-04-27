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
objectSpy                   = require 'object-spy'

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
obj =
    referer: "Mispelt"
    referrer: "Not quite a duplicate"
    magicNumber: NaN
    subObj:
        none: null

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
    obj.magicNumber += 1
    console.log "Got message from referrer: %s", subObj.referer

# Find out how the object is used directly
# (this is destructuring assignment syntax)
{wrapped: spy, getObservationsPromise} = objectSpy.watch obj
# There is also a `getObservations` method
# which takes a callback, instead of returning a promise.
processObj spy

# Format usage data as a table of sequential events
promisedData = getObservationsPromise()
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
Got message from referrer: Mispelt
Log-style report:
Tick        Event                 Path              Value type  (new) value (if stored)
0           read                  subObj            object
1           read                  magicNumber       NaN         NaN
2           write                 magicNumber       NaN         NaN
3           read                  subObj.none       null        null
4           write                 magicNumber       null        null
5           read                  magicNumber       null        null
6           write                 magicNumber       number      1
7           read                  subObj.referer    string      Mispelt

Event counts report:
Event: read
	Path              Count
	magicNumber       2
	subObj            1
	subObj.none       1
	subObj.referer    1
Event: write
	Path              Count
	magicNumber       3
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

#### `watch(obj)`
Returns an object with the following properties
- `wrapped`: A spy which can be substituted in client code
  for the `obj` argument, to collect usage data.
- `getObservations(cb)`: Calls the callback `cb` with `err` and `data` arguments,
  where `data` is the set of observations collected from `wrapped` to date.
- `getObservationsPromise()`: Returns a promise with the same effect as
  `getObservations()`

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

## Further reading

Visit the [wiki](../../wiki)
