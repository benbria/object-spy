path = require 'path'

srcRoot = path.join __dirname, '../src'

# Require a module relative to the root of the source code/pre-compiled code.
module.exports = (module) -> require path.join(srcRoot, module)
