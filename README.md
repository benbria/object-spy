# object-spy

Discover how code is using an object by sending it a spy instead.
In the process, find out what the object looks like to its clients.

## Suggested uses

#### Documentation

Determine the format of input data expected by some component.
(Output data can be analyzed as well, but with more limitations
until [this issue](../../issues/8) is addressed.)

#### Mocking objects

Run the code to be tested with a spy object,
and check what properties of the spy were used.
This assists with the process of writing mock object literals in test code,
speeding it up and leading to simpler test code.

#### Discovering dead code

Determine how much of an object is actually ever accessed.
(This is possible by inspection currently, but
the intention is to provide an automated tool, as described
[here](../../issues/16))

#### Investigating performance

Count the number of times that the various properties
of an object are used by client code.

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
# There is an `getObservations`
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

#### `watch(obj)`
Returns an object with the following properties
- `wrapped`: A spy which can be substituted for the `obj` argument
  to collect usage data.
- `getObservations(cb)`: Calls the callback `cb` with `err` and `data` arguments,
  where `data` is the set of observations collected from `wrapped` to date.
- `getObservationsPromise()`: Returns a promise with the same effect as
  `getObservations()`

## Further reading

Visit the [wiki](../../wiki)
