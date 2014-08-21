#!/usr/bin/env dart

import 'dart:io';
import 'dart:async';
import 'package:guinness/guinness.dart';
import 'package:path/path.dart' as path;
import 'package:dart2es6/transpiler.dart';

const String DUMMY_CLASS_NAME = "TEST_CLASS_NAME";
const String DUMMY_METHOD_NAME = "TEST_METHOD_NAME";

List<String> testFiles = [
    "unittest"
];

Future test(String p) {
  var curDir = path.dirname(path.fromUri(Platform.script));
  Map<String, List<String>> testCaseNames;
  var dart2es6Path = path.join(path.dirname(curDir), 'dart2es6');
  var preprocessorOutput = path.join(curDir, 'out', 'preprocessor', p + '.dart');
  var transpilerOutput = path.join(curDir, 'out', 'transpiler', p + '.js');
  var traceurOutput = path.join(curDir, 'out', 'traceur', p + '.js');

  var traceurRuntime = new File(path.join(curDir, "assets", "traceur.js")).readAsStringSync();

  // The entire Js file gets copied for each test so only one traceur call is needed
  // Dart is done the same way to match
  Future<String> _getJsOutput(String className, String methodName) {
    var p = path.join(curDir, 'temp-$className-$methodName.js');
    var code = new File(traceurOutput).readAsStringSync()
        .replaceAll(DUMMY_CLASS_NAME, className)
        .replaceAll(DUMMY_METHOD_NAME, methodName);
    var file = new File(p);
    var sink = file.openWrite(mode: FileMode.WRITE)
        ..write(traceurRuntime) // needed to run traceur output
        ..write(code);
    return sink.close().then((_) {
      return Process.run("node", [p]).then((result) {
        try {
          _checkResults(result);
        } catch (e) {
          throw "Error thrown while attempting to execute:\n$p\n\n$e";
        }
        file.delete();
        return result.stdout;
      });
    });
  }

  Future<String> _getDartOutput(String className, String methodName) {
    var p = path.join(curDir, 'temp-$className-$methodName.dart');
    var file = new File(p);
    var sink = file.openWrite(mode: FileMode.WRITE)
        ..write(new File(preprocessorOutput).readAsStringSync())
        ..write("\nmain() => print(new $className().$methodName());");
    return sink.close().then((_){
      return Process.run("dart", ['-c', p]).then((result) {
        try {
          _checkResults(result);
        } catch (e) {
          throw "Error thrown while attempting to execute:\n$p\n\n$e";
        }
        file.delete();
        return result.stdout;
      });
    });
  }

  /**
   * Runs method in dart & JS, compares results with guinness
   */
  void _testClass(String className, List<String> methodNames) {
    describe(_convertName(className), () {
      methodNames.forEach((methodName) {
        it(_convertName(methodName), () {
          Future dart = _getDartOutput(className, methodName);
          Future js = _getJsOutput(className, methodName);
          return Future.wait([js, dart]).then((results) {
            expect(results[0]).toEqual(results[1]);
          });
        });
      });
    });
  }

  new File(path.join(curDir, 'samples', p + '.dart')).readAsString().then((f) {
    var sink = new File(preprocessorOutput).openWrite();
    testCaseNames = _processTestFile(f, sink);
    sink.close();
  }).then((_) {
    return Process.run("dart", ['-c', dart2es6Path, '-o', transpilerOutput, preprocessorOutput])
        .then((ProcessResult results) {
          if (results.stdout.isNotEmpty) print(results.stdout);
          _checkResults(results);
          new File(transpilerOutput).writeAsStringSync(
              "\nconsole.log(new $DUMMY_CLASS_NAME().$DUMMY_METHOD_NAME());\n", mode: FileMode.APPEND);
        });
  }).then((_) {
    // needs `npm install -g traceur`
    assert(new File(transpilerOutput) != null);
    return Process.run("traceur", ['--out', traceurOutput, transpilerOutput])
        .then((ProcessResult results) => _checkResults(results));
  }).then((_) {
    testCaseNames.forEach(_testClass);
  });
}

String _convertName(String name) {
  return name
      .replaceAllMapped(new RegExp(r"([A-Z])"), (m) => " ${m.group(1)}")
      .replaceAll(new RegExp(r"\d$"), "")
      .toLowerCase();
}

void _checkResults(ProcessResult results) {
  if (results.exitCode != 0) {
    exitCode = results.exitCode;
    throw results.stderr;
  }
}

/**
 * TODO:
 * 1. Add a tree shaker to remove helper classes that are not used. Helper classes do not have a
 *    @describe, and if the test that uses them gets x'd, the helper should be removed too to not
 *    throw an error.
 * 2. Bug: If a method has @iit, the class must have @ddescribe or else all other classes's methods
 *    still get run. aka @iit is currently only local to the class that it's in
 * 3. Bug: Having a comment after [@describe, @it, ...] or after the class open brace breaks the
 *    regex and results in a non-match. Fix regex to allow these comments
 */
/// writes dart file with only selected test cases to sink, tree shakes helpers
/// returns names of tests
Map<String, List<String>> _processTestFile(String file, StringSink sink) {
  var classRegExpStr =
      r'\n(class\s+(\w+?)\s+{'
      r'[\s\S]*?'
      r'\n}\n)'; // assumes class ends with the first non-indented closing curly brace
  file = file.replaceAll(new RegExp('@xdescribe' + classRegExpStr), '')
      .replaceAll("import '../annotations.dart';", "");
  var ddescribeRegExp = new RegExp('@ddescribe' + classRegExpStr);
  var describeRegExp = new RegExp('@describe' + classRegExpStr);
  var classRegExp = ddescribeRegExp.hasMatch(file) ? ddescribeRegExp : describeRegExp;

  var methodRegExpStr =
      r'\n  .*?(\w+)\(.*?\) ?('
          r'{[\s\S]*?'      // block function body
          r'\n  }\n' // assumes method ends with first closing curly brace with indented two spaces
      r'|'
          r'=>[\s\S]*?;\n)';   // expression function body
  var iitRegExp = new RegExp('@iit' + methodRegExpStr);
  var itRegExp = new RegExp('@it' + methodRegExpStr);

  Map<String, List<String>> testNames = {};

  String _processClass(Match classMatch) {
    var className = classMatch.group(2);
    var methodNames = [];
    addMethodNameToList(match) => methodNames.add(match.group(1));

    var classStr = classMatch.group(1)
        .replaceAll(new RegExp('@xit' + methodRegExpStr), '');

    var iitMatches = iitRegExp.allMatches(classStr);
    if (iitMatches.isNotEmpty) {
      classStr = classStr.replaceAll(itRegExp, '').replaceAll('@iit\n', '');
      iitMatches.forEach(addMethodNameToList);
    } else {
      var matches = itRegExp.allMatches(classStr);
      matches.forEach(addMethodNameToList);
      classStr = classStr.replaceAll('@it\n', '');
    };

    assert(methodNames.isNotEmpty);
    testNames[className] = methodNames;
    return classStr;
  }

  file = file.replaceAllMapped(classRegExp, _processClass);
  sink.write(file);
  return testNames;
}

main() {
  Future.forEach(testFiles, (f) => test(f));
}
