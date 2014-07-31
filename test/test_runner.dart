#!/usr/bin/env dart

import 'dart:io';
import 'dart:async';
import 'package:guinness/guinness.dart';
import 'package:path/path.dart' as path;
import 'package:dart2es6/dart2es6.dart';


Future test(String p) {
  var curDir = path.dirname(path.fromUri(Platform.script));
  var testCaseNames;
  var preprocessorOutput = path.join(curDir, 'out', 'preprocessor', p + '.dart');
  var transpilerOutput = path.join(curDir, 'out', 'transpiler', p + '.js');
  var traceurOutput = path.join(curDir, 'out', 'traceur', p + '.js');

  // The entire Js file gets copied for each test so only one traceur call is needed
  // Dart is done the same way to match
  String _getJsOutput(String className, String methodName) {
    return "";
  }

  String _getDartOutput(String className, String methodName) {
    var temp = new File('temp.dart').openWrite()
        ..write(new File(preprocessorOutput).readAsStringSync())
        ..write("\nmain() => print(new $className().$methodName())")
        ..close();
    return "";
  }

  void _testClass(String className, List<String> methodNames) {
    describe(_convertName(className), () {
      methodNames.forEach((methodName) {
        var dart = _getDartOutput(className, methodName);
        var js = _getJsOutput(className, methodName);
        it(_convertName(methodName), () {
          expect(dart).toEqual(js);
        });
      });
    });
  }

  new File(path.join(curDir, 'samples', p + '.dart')).readAsString().then((f) {
    var sink = new File(preprocessorOutput).openWrite();
    testCaseNames = _processTestFile(f, sink);
    sink.close();
  }).then((_) {
    var dart2es6Path = path.join(path.dirname(curDir), 'dart2es6');
    return Process.run("dart", [dart2es6Path, '-o', transpilerOutput, preprocessorOutput])
        .then((ProcessResult results) {
          _checkResults(results);
          new File(transpilerOutput).writeAsStringSync(
              "\nconsole.log(new TEST_CLASS_NAME().TEST_METHOD_NAME());\n", mode: FileMode.APPEND);
        });
  }).then((_) {
    // needs `npm install -g traceur`
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
    print(results.stdout);
    print(results.stderr);
    exit(exitCode);
  }
}

//TODO: Tree shake unused helper classes
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

List<String> testFiles = [
  "unittest"
];
main() {
  Future.forEach(testFiles, (f) => test(f));
}
