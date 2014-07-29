library dart2es6;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/sdk.dart' show DartSdk;
import 'package:analyzer/src/generated/sdk_io.dart' show DirectoryBasedDartSdk;
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:code_transformers/resolver.dart' show dartSdkDirectory;
import 'visitor.dart';

class Transpiler {
  CompilationUnit compilationUnit;
  MainVisitor visitor;

  Transpiler.fromPath(String path, {test: false})
      : visitor = (test ? new TestVisitor() : new MainVisitor()) {
    JavaSystemIO.setProperty("com.google.dart.sdk", dartSdkDirectory);
    DartSdk sdk = DirectoryBasedDartSdk.defaultSdk;

    AnalysisContext context = AnalysisEngine.instance.createAnalysisContext();
    context.sourceFactory = new SourceFactory([new DartUriResolver(sdk), new FileUriResolver()]);
    Source source = new FileBasedSource.con1(new JavaFile(path));

    ChangeSet changeSet = new ChangeSet();
    changeSet.addedSource(source);
    context.applyChanges(changeSet);
    LibraryElement libElement = context.computeLibraryElement(source);

    compilationUnit = context.resolveCompilationUnit(source, libElement);
  }

  String transpile() {
    return compilationUnit.accept(visitor).toString();
  }
}
