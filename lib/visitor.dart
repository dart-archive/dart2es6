library dart2es6.visitor;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/element.dart' show DartType;
import 'package:path/path.dart' as Path;
import 'transpiler.dart';
import 'visitor_null.dart';
import 'writer.dart';
import 'dart:io';

part 'visitor_block.dart';
part 'visitor_test.dart';
part "replacements.dart";


/**
 * Transpilation starts with this visitor. Processes top level declarations and directives,
 * assigning tasks to other visitors.
 */
class MainVisitor extends NullVisitor {

  final String path;

  MainVisitor(this.path);

  visitClassDeclaration(ClassDeclaration node) {
    return node.accept(new ClassVisitor());
  }

  visitCompilationUnit(CompilationUnit node) {
    IndentedStringBuffer output = new IndentedStringBuffer();
    node.directives.where((d) => d is! PartDirective).forEach((directive) {
      output.writeln(directive.accept(this));
    });

    node.declarations.forEach((declaration) {
      var d = declaration.accept(this);
      output.write(d);
      output.write('\n');
    });

    node.directives.where((d) => d is PartDirective).forEach((PartDirective part) {
      output.writeln(part.accept(this));
    });
    return output;
  }

  visitExportDirective(ExportDirective node) {
    return visitNameSpaceDirective(node);
  }

  visitFunctionDeclaration(FunctionDeclaration node) {
    return node.accept(new BlockVisitor());
  }

  visitFunctionTypeAlias(FunctionTypeAlias node) {
    return "// $node";
  }

  visitHideCombinator(HideCombinator node) {
    assert("Hide not supported" == "");
    return "";
  }

  visitImportDirective(ImportDirective node) {
    return visitNameSpaceDirective(node);
  }

  visitNameSpaceDirective(NamespaceDirective node) {
    var uri = node.uri.stringValue;
    if (uri.startsWith("package:") || uri.startsWith("dart:")) {
      print("Tried importing '$uri', skipping.");
      return "";
    };
    uri = uri.replaceAll(".dart", "");
    uri = "./" + uri;

    if (node is ImportDirective && node.asToken != null) {
      assert (node.combinators.isEmpty);
      return "module ${node.prefix.name} from '$uri';";
    }

    var output = new IndentedStringBuffer();
    output.write(node is ImportDirective ? "import " : "export ");

    if (node.combinators.isEmpty) {
      output.write(node is ImportDirective ? "\$" : "*");
    } else {
      output.write("{\n");
      var show = node.combinators.map((c) => c.accept(this)).join(",\n");
      output..write(new IndentedStringBuffer(show).indent())
        ..write("}");
    }
    output.write(" from '$uri';");
    return output;
  }

  visitLibraryDirective(LibraryDirective node) => "";

  visitPartDirective(PartDirective node) {
    var uri = node.uri.stringValue;
    var p = Path.join(Path.dirname(path), uri);
    return new Transpiler.fromPath(p).transpile();
  }

  visitPartOfDirective(PartOfDirective node) {
    return "/* $node */";
  }

  visitShowCombinator(ShowCombinator node) {
    return node.shownNames.map((n) => n.name).join(",\n");
  }

  visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    var visitor = new BlockVisitor();
    var vars = node.variables.variables.map((v) => v.accept(visitor)).join(', ');
    return '$vars;'; // TODO: types, const, final
  }
}


// Most of these fields are not actually used
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
    if (name[0] != "_") output.write("export "); // private
    output.write("class $name ");
    if (node.extendsClause != null) output.write("${node.extendsClause.accept(this)} ");
    output.write("{\n");

    var input = new IndentedStringBuffer();
    input.write(node.members.where((m) => m is! FieldDeclaration).map((ClassMember member) {
      return member.accept(this);
    }).join('\n\n'));
    input.indent();
    output.write(input);

    output.write('}\n');
    fields.where((f) => f.isStatic).forEach((field) {
      var value = field.value == null ? "null" : field.value.accept(new BlockVisitor());
      output.write("$name.${field.name} = $value;\n");
    });
    return output;
  }

  visitExtendsClause(ExtendsClause node) => "extends ${node.superclass.name.name}";

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
