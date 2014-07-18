library dart2es6;

import 'package:analyzer/analyzer.dart';
import 'visitor.dart';

class Transpiler {
  CompilationUnit compilationUnit;
  MainVisitor visitor;
  Transpiler.fromAst(this.compilationUnit) : visitor = new MainVisitor();

  String transpile() {
    return compilationUnit.accept(visitor).toString();
  }
}
