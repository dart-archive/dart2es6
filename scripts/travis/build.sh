#!/bin/bash
set -e
. ./scripts/env.sh

mkdir -p test/out/preprocessor test/out/traceur test/out/transpiler
dart -c test/test_runner.dart
