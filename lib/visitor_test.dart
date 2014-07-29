part of dart2es6.visitor;

class TestVisitor extends MainVisitor {
  visitClassDeclaration(ClassDeclaration node) {
    try {
      return super.visitClassDeclaration(node);
    } catch (e, s) {
      print("Transpilation failed & skipped for class `${node.name.name}`. Which threw:\n$e$s");
      exitCode = 1;
      return "// class ${node.name.name} threw ${e.toString().split('\n')[0]}";
    }
  }

  visitFunctionDeclaration(FunctionDeclaration node) {
    try {
      return super.visitFunctionDeclaration(node);
    } catch (e, s) {
      print("Transpilation failed & skipped for top level function `${node.name.name}`. "
      "Which threw:\n$e$s");
      exitCode = 1;
      return "// function ${node.name.name} threw ${e.toString().split('\n')[0]}";
    }
  }
}
