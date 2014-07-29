#!/usr/bin/env dart

import 'dart:io';
import 'dart:async';
import 'package:guinness/guinness.dart';
import 'package:path/path.dart' as path;


Future test(p) {
  var curDir = path.dirname(path.fromUri(Platform.script));
  var file = new File(path.join(curDir, 'samples', p)).readAsString();
  var sink = new File(path.join(curDir, 'out', p)).openWrite();
  var testCaseNames = file.then((f) {
    _processTestFile(f, sink);
    sink.close();
  });
}

/// writes dart file with only selected test cases to sink, returns names of tests
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
  print(testNames);
  return testNames;
}

List<String> testFiles = [
  "unittest.dart"
];
main() {
  Future.forEach(testFiles, (f) => test(f));
}
