library dart2es6.visitor;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/element.dart' show DartType;
import 'visitor_null.dart';
import 'writer.dart';
import 'dart:io';

part 'visitor_block.dart';
part 'visitor_test.dart';
part "replacements.dart";

_doesNotShadow(String name) => true; // TODO: top level shadowing check against globals

class MainVisitor extends NullVisitor {

  MainVisitor();

  visitClassDeclaration(ClassDeclaration node) {
    return node.accept(new ClassVisitor());
  }

  visitCompilationUnit(CompilationUnit node) {
    IndentedStringBuffer output = new IndentedStringBuffer();
    node.declarations.forEach((declaration) {
      var d = declaration.accept(this);
      output.write(d);
      output.write('\n');
    });
    return output;
  }

  visitFunctionDeclaration(FunctionDeclaration node) {
    return node.accept(new BlockVisitor());
  }
}

class Field {
  final String name;
  final Expression value;
  final String type;
  final bool isFinal;
  final bool isStatic;
  final bool isConst;
  Field(this.name, this.value, this.type, this.isFinal, this.isStatic, this.isConst);
  toString() => name;
}

class Method {
  final String name;
  Method(this.name);
  toString() => name;
}

/**
 * A separate visitor for each class, keeping track of fields
 */
class ClassVisitor extends NullVisitor {

  String name;
  List<Field> fields = [];
  List<Method> methods = [];

  ClassVisitor();

  visitClassDeclaration(ClassDeclaration node) {
    assert(name == null);
    name = node.name.toString();
    node.members.where((m) => m is FieldDeclaration).forEach((FieldDeclaration member) {
      var isStatic = member.isStatic;
      var type = member.fields.type == null ? null : member.fields.type.name.name;
      var isConst = member.fields.isConst;
      var isFinal = member.fields.isFinal;
      member.fields.variables.forEach((VariableDeclaration declaration) {
        var field = new Field(declaration.name.toString(), declaration.initializer,
            type, isFinal, isStatic, isConst);
        fields.add(field);
      });
    });
    node.members.where((m) => m is MethodDeclaration).forEach((MethodDeclaration member) {
      var method = new Method(member.name.toString());
      methods.add(method);
    });

    var output = new IndentedStringBuffer();
    if (node.documentationComment != null) {
      output.writeln(node.documentationComment.accept(new BlockVisitor()));
    }
    output.write("export class $name {\n"); // TODO: Static fields
    var input = new IndentedStringBuffer();
    input.write(node.members.where((m) => m is! FieldDeclaration).map((ClassMember member) {
      return member.accept(this);
    }).join('\n\n'));
    input.indent();
    output.write(input);
    output.write('}\n');
    return output;
  }

  visitMethodDeclaration(MethodDeclaration node) {
    return node.accept(new BlockVisitor(this));
  }

  visitConstructorDeclaration(ConstructorDeclaration node) {
    return node.accept(new ConstructorVisitor(this));
  }
}


class ConstructorVisitor extends BlockVisitor {

  Set<String> initializedFieldNames = new Set();
  ConstructorVisitor(cls): super(cls);

  String initializeFields() {
    var value;
    return cls.fields.where((f) => !f.isStatic).map((f) {
      if (f.value != null) {
        value = f.value.accept(this);
      } else {
        if (initializedFieldNames.contains(f.name)) {
          value = f.name;
        } else {
          value = "null";
        }
      }
      return "this.${f.name} = $value;";
    }).join('\n');
  }

  visitConstructorDeclaration(ConstructorDeclaration node) {
    IndentedStringBuffer output = new IndentedStringBuffer()
        ..write('constructor')
        ..write(node.parameters.accept(this))
        ..write(' {\n')
        ..write(node.body.accept(this).indent())
        ..write('}');
    return output;
  }

  visitBlockFunctionBody(BlockFunctionBody node) {
    IndentedStringBuffer output = new IndentedStringBuffer(initializeFields())
        ..write('\n')
        ..write(super.visitBlockFunctionBody(node));
    return output;
  }

  visitEmptyFunctionBody(EmptyFunctionBody node) {
    return new IndentedStringBuffer(initializeFields());
  }

  visitFieldFormalParameter(FieldFormalParameter node) {
    assert(node.parameters == null);
    var name = node.identifier.toString();
    initializedFieldNames.add(name);
    return name;
  }
}
