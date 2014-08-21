[![Build Status](https://travis-ci.org/antingshen/dart2es6.svg?branch=master)](https://travis-ci.org/antingshen/dart2es6)

# dart2es6

_The Dart to ECMAScript 6 transpiler_

## For design doc & TODO's, see [wiki page](https://github.com/antingshen/dart2es6/wiki/Doc)

## Usage

Get dependencies with `pub get` then run:

`./dart2es6 input_path.dart -o output_path.js`

See `--help` for more options.

#### Example: Transpiling Angular change detection

AngularDart's change detection library is included in the `change_detection` folder as an example.
The folder included here has been modified from the original with some unsupported code removed.

To transpile this example:

    cd change_detection
    ./transpile
    
The output will be located in `change_detection/out`

Uncomment line in `change_detection/transpile` to transpile change detection tests as well.

Currently, change detection and its tests transpile incorrectly since some code are not supported.
See design doc for more info.

#### Running unit tests

Install dependencies:

- Install `node` and `npm`
- Install `traceur`: `npm install -g traceur`

Then run unit tests:

    mkdir -p test/out/preprocessor test/out/traceur test/out/transpiler
    dart -c test/test_runner.dart

#### Problems?

Check environment is set correctly. See `scripts/travis/setup.sh` and `scripts/travis/build.sh`.