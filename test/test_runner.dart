import 'dart:io';
import 'dart:async';


class TestRunner {
  String path;

  TestRunner(this.path);

  Future test() {
    return new File('samples' + this.path).readAsString().then((file) {

    });
  }
}


List<String> testFiles = [
  "unittest.dart"
];
main() {
  Future.forEach(testFiles, (f) => new TestRunner(f).test());
}
