library dart2es6.visitor;

import 'package:analyzer/analyzer.dart';
import 'null_visitor.dart';
import 'writer.dart';

Map<String, String> REPLACE = {
    'print': 'console.log',
};

class MainVisitor extends NullVisitor {

  MainVisitor();

  visitClassDeclaration(ClassDeclaration node) {
    return node.accept(new ClassVisitor());
  }

  IndentedStringBuffer visitCompilationUnit(CompilationUnit node) {
    IndentedStringBuffer output = new IndentedStringBuffer();
    node.declarations.forEach((declaration) {
      var d = declaration.accept(this);
      output.write(d);
    });
    return output;
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
}

/**
 * A separate visitor for each class, keeping track of fields
 */
class ClassVisitor extends NullVisitor {

  String name;
  List<Field> fields = [];

  ClassVisitor();

  visitClassDeclaration(ClassDeclaration node) {
    assert(name == null);
    name = node.name.toString();
    node.members.where((m) => m is FieldDeclaration).forEach((FieldDeclaration member) {
      var isStatic = member.isStatic;
      var type = member.fields.type.name.name;
      var isConst = member.fields.isConst;
      var isFinal = member.fields.isFinal;
      member.fields.variables.forEach((VariableDeclaration declaration) {
        var field = new Field(declaration.name.toString(), declaration.initializer,
            type, isFinal, isStatic, isConst);
        fields.add(field);
      });
    });

    var output = new IndentedStringBuffer("class $name {\n");
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


class BlockVisitor extends NullVisitor {

  final ClassVisitor cls;
  BlockVisitor(this.cls);

  bool _isField(name) {
    if (name is SimpleIdentifier) name = name.name;
    return (cls != null && cls.fields.where((f) => f.name == name).isNotEmpty);
  }

  visitArgumentList(ArgumentList node) {
    var buffer = new IndentedStringBuffer('(');
    buffer.write(node.arguments.map((a) => a.accept(this)).join(', '));
    buffer.write(')');
    return buffer;
  }

  visitAssertStatement(AssertStatement node) {
    // TODO: Keep asserts or not?
    return "// console.assert(${node.condition.accept(this)});";
  }

  visitAssignmentExpression(AssignmentExpression node) {
    assert(['=', '+=', '-=', '*=', '/=', '%=', '&=', '^=', '|=', '<<=', '>>=']
        .contains(node.operator.toString()));
    return "${node.leftHandSide.accept(this)} ${node.operator} ${node.rightHandSide.accept(this)}";
  }

  visitBinaryExpression(BinaryExpression node) {
    var op = node.operator.toString();
    assert(["+","-","*","/","==","!=","<","<=",">",">="].contains(op) || print(op));
    if (op == "==" || op == "!=") op += "=";
    return "${node.leftOperand.accept(this)} $op ${node.rightOperand.accept(this)}";
  }

  visitBlock(Block node) {
    IndentedStringBuffer output = new IndentedStringBuffer();
    output.write(node.statements.map((s) => s.accept(this)).join('\n'));
    return output;
  }

  visitBlockFunctionBody(BlockFunctionBody node) {
    return node.block.accept(this);
  }

  visitBooleanLiteral(BooleanLiteral node) => node.literal.toString();

  visitConditionalExpression(ConditionalExpression node) {
    return "${node.condition.accept(this)} ? ${node.thenExpression.accept(this)}"
        " : ${node.elseExpression.accept(this)}";
  }

  visitConstructorName(ConstructorName node) {
    // TODO: implement different constructors
    return node.type.name.toString();
  }

  visitDoubleLiteral(DoubleLiteral node) {
    return node.literal.toString();
  }

  visitExpressionFunctionBody(ExpressionFunctionBody node) {
    return "return ${node.expression.accept(this)};";
  }

  visitExpressionStatement(ExpressionStatement node) {
    assert(node.semicolon != null);
    return "${node.expression.accept(this)};";
  }

  visitFormalParameterList(FormalParameterList node) {
    var buffer = new IndentedStringBuffer('(');
    buffer.write(node.parameters
        .where((p) => p.kind == ParameterKind.REQUIRED)
        .map((p) => p.accept(this))
        .join(', '));
    // TODO: optional arguments
    buffer.write(')');
    return buffer;
  }

  visitForStatement(ForStatement node) {
    assert(node.initialization == null);
    IndentedStringBuffer output = new IndentedStringBuffer()
        ..write("for (")
        ..write(node.variables.accept(this))
        ..write("; ")
        ..write(node.condition.accept(this))
        ..write("; ")
        ..write(node.updaters.map((e) => e.accept(this)).join(', '))
        ..write(") {\n")
        ..write(node.body.accept(this).indent())
        ..write("}");
    return output;
  }

  visitFunctionExpression(FunctionExpression node) {
    IndentedStringBuffer output = new IndentedStringBuffer()
        ..write(node.parameters.accept(this))
        ..write(" => {\n")
        ..write(new IndentedStringBuffer(node.body.accept(this)).indent())
        ..write("}");
    return output;
  }

  visitIfStatement(IfStatement node) {
    IndentedStringBuffer output = new IndentedStringBuffer()
        ..write("if (")
        ..write(node.condition.accept(this))
        ..write(") {\n")
        ..write(new IndentedStringBuffer(node.thenStatement.accept(this)).indent())
        ..write("}");
    if (node.elseStatement != null) {
      output.write(" else ");
      if (node.elseStatement is IfStatement) {
        output.write(node.elseStatement.accept(this));
      } else {
        output..write("{\n")
            ..write(node.elseStatement.accept(this).indent())
            ..write("}");
      }
    }
    return output;
  }

  visitIndexExpression(IndexExpression node) {
    assert(node.isCascaded == false);
    return "${node.target.accept(this)}[${node.index.accept(this)}]";
  }

  visitInstanceCreationExpression(InstanceCreationExpression node) {
    // TODO: replace HashMap
    return "new ${node.constructorName.accept(this)}${node.argumentList.accept(this)}";
  }

  visitIntegerLiteral(IntegerLiteral node) {
    return node.literal.toString();
  }

  visitInterpolationExpression(InterpolationExpression node) {
    return "\${${node.expression.accept(this)}}";
  }

  visitInterpolationString(InterpolationString node) {
    return node.value;
  }

  visitListLiteral(ListLiteral node) {
    return "[${node.elements.map((e) => e.accept(this)).join(', ')}]";
  }

  visitMethodDeclaration(MethodDeclaration node) {
    IndentedStringBuffer output = new IndentedStringBuffer();
    if (node.isGetter) output.write('get ');
    if (node.isSetter) output.write('set ');
    output.write(node.name);
    if (node.parameters != null) {
      output.write(node.parameters.accept(this));
      output.write(' ');
    } else {
      output.write('() ');
    }
    output.write("{\n");
    var body = node.body.accept(this);
    if (body is! IndentedStringBuffer) body = new IndentedStringBuffer(body);
    output.write(body.indent());
    output.write('}');
    return output;
  }

  visitMethodInvocation(MethodInvocation node) {
    assert(!node.isCascaded);
    var target = "";
    if (node.target != null) {
      assert(node.period != null);
      target = '${node.target.accept(this)}.';
    } else if (cls.fields.where((f) => f.name == node.methodName).isNotEmpty) {
      target = "this.";
    }
    return "$target${node.methodName.accept(this)}${node.argumentList.accept(this)}";
  }

  visitNullLiteral(NullLiteral node) => "null";

  visitParenthesizedExpression(ParenthesizedExpression node) {
    return "(${node.expression.accept(this)})";
  }

  visitPostfixExpression(PostfixExpression node) {
    assert(["++", "--"].contains(node.operator.toString()));
    return "${node.operand.accept(this)}${node.operator}";
  }

  visitPrefixedIdentifier(PrefixedIdentifier node) {
    return "${node.prefix.accept(this)}.${node.identifier.name}";
  }

  visitPropertyAccess(PropertyAccess node) {
    assert(!node.isCascaded);
    return "${node.target.accept(this)}.${node.propertyName.name}";
  }

  visitReturnStatement(ReturnStatement node) {
    return "return ${node.expression.accept(this)};";
  }

  visitSimpleFormalParameter(SimpleFormalParameter node) {
    return node.identifier.name;
  }

  visitSimpleIdentifier(SimpleIdentifier node) {
    var name = node.name;
    // Very stupid unresolved check, broken by shadowing, but should work
    if (_isField(name)) {
      assert(!REPLACE.containsKey(name));
      return "this.${name}";
    }
    if (REPLACE.containsKey(name)) return REPLACE[name];
    return name;
  }

  visitSimpleStringLiteral(SimpleStringLiteral node) {
    assert(!node.isMultiline && !node.isRaw);
    return node.literal.toString();
  }

  visitStringInterpolation(StringInterpolation node) {
    return '${node.beginToken}${node.elements.map((e) => e.accept(this)).join()}${node.endToken}';
  }

  visitSuperExpression(SuperExpression node) => "super";

  visitThisExpression(ThisExpression node) => "this";

  visitVariableDeclaration(VariableDeclaration node) {
    var shadows = cls.fields.where((f) => f.name == node.name.toString());
    if (shadows.isNotEmpty) throw "Variable shadows field: ${shadows.first}";
    shadows = REPLACE.keys.where((f) => f == node.name.toString());
    if (shadows.isNotEmpty) throw "Variable shadows global/builtin: ${shadows.first}";

    if (node.initializer == null) return node.name.toString();
    return "${node.name.toString()} = ${node.initializer.accept(this)}";
  }

  visitVariableDeclarationList(VariableDeclarationList node) {
    var vars = node.variables.map((v) => v.accept(this)).join(', ');
    return 'var $vars'; // TODO: types, const, final
  }

  visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    return "${node.variables.accept(this)};";
  }

  visitWhileStatement(WhileStatement node) {
    IndentedStringBuffer output = new IndentedStringBuffer()
        ..write("while (")
        ..write(node.condition.accept(this))
        ..write(") {\n")
        ..write(node.body.accept(this).indent())
        ..write("}");
    return output;
  }
}
