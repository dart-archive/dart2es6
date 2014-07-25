import "package:guinness/guinness.dart";
import 'package:analyzer/analyzer.dart';
import "package:dart2es6/dart2es6.dart";

main() {
  test("watchgroup", "");
}

test(String input, [String output]) {
//  print(input);
  print('---debug---');

  var result = new Transpiler.fromPath("test/samples/$input.dart").transpile();
  print("---output---");
  print(result);
}

var INPUT_STOPWATCH = """
class AvgStopwatch {
  int _count = 0;
  String name;

  static num numCreated = 0;

  AvgStopwatch(this.name) {
    print('new stopwatch created!');
  }

  int get count => _count;
  set count(val) => _count = val;

  void reset() {
    _count = 0;
    super.reset();
  }

  int increment(int count) => _count += count;

  double get ratePerMs => elapsedMicroseconds == 0
      ? 0.0
      : _count / elapsedMicroseconds * 1000;
}
""".trim();
