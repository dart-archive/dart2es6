part of dart2es6.visitor;

class BlockVisitor extends NullVisitor {

  final ClassVisitor cls;
  String errorVariableName;

  BlockVisitor([this.cls = null]);

  Field _getField(name) {
    if (cls == null) return null;
    if (name is SimpleIdentifier) name = name.name;
    var fields = cls.fields.where((f) => f.name == name);
    if (fields.isEmpty) return null;
    assert (fields.length == 1);
    return fields.first;
  }

  _checkDeclarationShadowing(String name) {
    var shadows = cls == null ? [] : cls.fields.where((f) => f.name == name);
    if (shadows.isNotEmpty) {
      throw "Variable shadows field: ${name}" + (cls == null ? "" : " in ${cls.name}");
    }
    shadows = GLOBAL_REPLACE.keys.where((f) => f == name);
    if (shadows.isNotEmpty) throw "Variable shadows global/builtin: ${name}";
  }

  visitAdjacentStrings(AdjacentStrings node) {
    return node.strings.map((s) => s.accept(this)).join(' + ');
  }

  visitArgumentList(ArgumentList node) {
    var buffer = new IndentedStringBuffer('(');
    buffer.write(node.arguments.map((a) => a.accept(this)).join(', '));
    buffer.write(')');
    return buffer;
  }

  visitAsExpression(AsExpression node) => node.expression.accept(this);

  visitAssertStatement(AssertStatement node) {
    // TODO: Keep asserts or not?
    return "/* console.assert(${node.condition.accept(this)}); */";
  }

  visitAssignmentExpression(AssignmentExpression node) {
    assert(['=', '+=', '-=', '*=', '/=', '%=', '&=', '^=', '|=', '<<=', '>>=']
        .contains(node.operator.toString()));
    return "${node.leftHandSide.accept(this)} ${node.operator} ${node.rightHandSide.accept(this)}";
  }

  visitBinaryExpression(BinaryExpression node) {
    var op = node.operator.toString();
    assert(["+","-","*","/","%","==","!=","<","<=",">",">=","&&","||","&","|","^"].contains(op));
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

  visitBreakStatement(BreakStatement node) => "break;";

  visitConditionalExpression(ConditionalExpression node) {
    return "${node.condition.accept(this)} ? ${node.thenExpression.accept(this)}"
        " : ${node.elseExpression.accept(this)}";
  }

  visitConstructorName(ConstructorName node) {
    // TODO: implement different constructors
    // assert(node.name == null); TODO: uncomment
    return node.type.name.toString();
  }

  visitComment(Comment node) {
    return node.tokens.map((t) => t.toString()).join().split("\n").map((line) {
      var trimmed = line.trim();
      if (trimmed[0] == '*') trimmed = " $trimmed";
      return trimmed;
    }).join('\n');
  }

  visitDefaultFormalParameter(DefaultFormalParameter node) {
    // TODO: check for shadowing in methods
    return "${node.identifier.name} = " +
        (node.defaultValue == null ? "null" : node.defaultValue.accept(this).toString());
  }

  visitDoStatement(DoStatement node) {
    var output = new IndentedStringBuffer()
        ..write("do {\n")
        ..write(new IndentedStringBuffer(node.body.accept(this)).indent())
        ..write("}\nwhile(")
        ..write(node.condition.accept(this))
        ..write(");");
    return output;
  }

  visitDoubleLiteral(DoubleLiteral node) {
    return node.literal.toString();
  }

  visitEmptyFunctionBody(EmptyFunctionBody node) {
    return 'throw new Error("abstract function not implemented");';
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
        .where((p) => p.kind == ParameterKind.REQUIRED || p.kind == ParameterKind.POSITIONAL)
        .map((p) => p.accept(this))
        .join(', '));
    // TODO: named arguments
    buffer.write(')');
    return buffer;
  }

  visitForStatement(ForStatement node) {
    assert(node.initialization == null || node.variables == null);
    IndentedStringBuffer output = new IndentedStringBuffer()
      ..write("for (")
      ..write(node.initialization == null ? "": node.initialization.accept(this))
      ..write(node.variables == null ? "" : node.variables.accept(this))
      ..write("; ")
      ..write(node.condition.accept(this))
      ..write("; ")
      ..write(node.updaters == null ? "" : node.updaters.map((e) => e.accept(this)).join(', '))
      ..write(") {\n")
      ..write(new IndentedStringBuffer(node.body.accept(this)).indent())
      ..write("}");
    return output;
  }

  visitForEachStatement(ForEachStatement node) {
    assert(node.awaitKeyword == null);
    var identifier;
    if (node.loopVariable != null) {
      identifier = "var " + node.loopVariable.identifier.name;
    } else {
      identifier = node.identifier.name;
    }
    var output = new IndentedStringBuffer()
        ..write("for ($identifier of ")
        ..write(node.iterator.accept(this))
        ..write(") {\n")
        ..write(new IndentedStringBuffer(node.body.accept(this)).indent())
        ..write("}");
    return output;
  }

  visitFunctionDeclaration(FunctionDeclaration node) {
    assert(_doesNotShadow(node.name.name));
    assert(node.isGetter == false);
    assert(node.isSetter == false);
    IndentedStringBuffer output = new IndentedStringBuffer()
        ..write("function ")
        ..write(node.name.name)
        ..write(node.functionExpression.parameters.accept(this))
        ..write(" {\n")
        ..write(new IndentedStringBuffer(node.functionExpression.body.accept(this)).indent())
        ..write("}");
    return output;
  }

  visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    return node.functionDeclaration.accept(this);
  }

  visitFunctionExpression(FunctionExpression node) {
    IndentedStringBuffer output = new IndentedStringBuffer()
        ..write(node.parameters.accept(this))
        ..write(" => {\n")
        ..write(new IndentedStringBuffer(node.body.accept(this)).indent())
        ..write("}");
    return output;
  }

  visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    var output = new IndentedStringBuffer()
        ..write("(function")
        ..write(node.argumentList.accept(this))
        ..write(" {\n")
        ..write(new IndentedStringBuffer(node.function.accept(new BlockVisitor(cls))).indent())
        ..write("})()");
    return output;
  }

  visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    return node.identifier.name;
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
            ..write(new IndentedStringBuffer(node.elseStatement.accept(this)).indent())
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
    var typeName = node.constructorName.type.name.name;
    if (["Map", "HashMap"].contains(typeName)) {
      assert(node.argumentList.accept(this).toString() == "()");
      return "{}";
    } else if (typeName == "List") {
      if (node.argumentList.accept(this).toString() != "()") {
        print("Arguments to List constructor ignored: $node");
      } // TODO: List.generate, List(size).
      return "[]";
    }
    return "new ${node.constructorName.accept(this)}${node.argumentList.accept(this)}";
  }

  visitIntegerLiteral(IntegerLiteral node) {
    return node.literal.toString();
  }

  visitInterpolationExpression(InterpolationExpression node) {
    return "\${${node.expression.accept(this)}}";
  }

  visitInterpolationString(InterpolationString node) {
    return node.contents.toString();
  }

  visitIsExpression(IsExpression node) {
    var types = {
        "num" : "number",
        "String" : "string",
        "Map" : "object",
        "List" : "object",
        "Function" : "function",
    };
    var type = node.type.name.name;
    var jsType = types[type];
    if (jsType == null) {
      return "${node.expression.accept(this)} instanceof $type"; // TODO: make this better
    }
    return "typeof ${node.expression.accept(this)} == '$jsType'";
  }

  visitListLiteral(ListLiteral node) {
    return "[${node.elements.map((e) => e.accept(this)).join(', ')}]";
  }

  visitMapLiteral(MapLiteral node) {
    return "{" + node.entries.map((n) => n.accept(this)).join(", ") + "}";
  }

  visitMapLiteralEntry(MapLiteralEntry node) {
    return "${node.key.accept(this)} : ${node.value.accept(this)}";
  }

  visitMethodDeclaration(MethodDeclaration node) {
    IndentedStringBuffer output = new IndentedStringBuffer();
    if (node.documentationComment != null) {
      output.writeln(node.documentationComment.accept(this));
    }
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
    String method = node.methodName.accept(this);
    if (node.target != null) {
      assert(node.period != null);
      target = '${node.target.accept(this)}.';
      method = _replacedField(node.target.bestType, method);
    } else if (cls != null && cls.methods.where((f) => f.name == node.methodName.name).isNotEmpty) {
      target = "this.";
    }
    return "$target$method${node.argumentList.accept(this)}";
  }

  visitNullLiteral(NullLiteral node) => "null";

  visitParenthesizedExpression(ParenthesizedExpression node) {
    return "(${node.expression.accept(this)})";
  }

  visitPostfixExpression(PostfixExpression node) {
    assert(["++", "--"].contains(node.operator.toString()));
    return "${node.operand.accept(this)}${node.operator}";
  }

  visitPrefixExpression(PrefixExpression node) {
    assert(["!", "++", "--", "-"].contains(node.operator.toString()));
    return "${node.operator}${node.operand.accept(this)}";
  }

  visitPrefixedIdentifier(PrefixedIdentifier node) {
    return "${node.prefix.accept(this)}.${node.identifier.name}";
  }

  visitPropertyAccess(PropertyAccess node) {
    assert(!node.isCascaded);
    return "${node.target.accept(this)}.${node.propertyName.name}";
  }

  visitRethrowExpression(RethrowExpression node) {
    assert(errorVariableName != null);
    return "throw $errorVariableName";
  }

  visitReturnStatement(ReturnStatement node) {
    if (node.expression == null) return "return;";
    return "return ${node.expression.accept(this)};";
  }

  visitSimpleFormalParameter(SimpleFormalParameter node) {
    return node.identifier.name; // TODO: check for shadowing in methods
  }

  visitSimpleIdentifier(SimpleIdentifier node) {
    var name = node.name;
    // unresolved check, broken by shadowing, but should work usually
    var field = _getField(name);
    if (field != null) {
      assert(!GLOBAL_REPLACE.containsKey(name));
      if (field.isStatic) {
        return "${cls.name}.$name";
      } else {
        return "this.$name";
      }
    }
    if (GLOBAL_REPLACE.containsKey(name)) return GLOBAL_REPLACE[name];
    return name;
  }

  visitSimpleStringLiteral(SimpleStringLiteral node) {
    assert(!node.isMultiline && !node.isRaw);
    return node.literal.toString();
  }

  visitStringInterpolation(StringInterpolation node) {
    // TODO: Multiline
    return '${node.elements.map((e) => e.accept(this)).join()}';
  }

  visitSuperExpression(SuperExpression node) => "super";

  visitSwitchCase(SwitchCase node) {
    var statements = node.statements.map((s) => s.accept(this)).join('\n');
    var output = new IndentedStringBuffer()
        ..write("case (")
        ..write(node.expression.accept(this))
        ..write("):\n")
        ..write(new IndentedStringBuffer(statements).indent());
    return output;
  }

  visitSwitchDefault(SwitchDefault node) {
    var statements = node.statements.map((s) => s.accept(this)).join("\n");
    return "default:\n" + new IndentedStringBuffer(statements).indent().toString();
  }

  visitSwitchStatement(SwitchStatement node) {
    var members = node.members.map((m) => m.accept(this)).join('\n');
    var output = new IndentedStringBuffer()
        ..write("switch (")
        ..write(node.expression.accept(this))
        ..write(") {\n")
        ..write(new IndentedStringBuffer(members).indent())
        ..write("}");
    return output;
  }

  visitThisExpression(ThisExpression node) => "this";

  visitThrowExpression(ThrowExpression node) => "throw ${node.expression.accept(this)}";

  visitTryStatement(TryStatement node) {
    var output = new IndentedStringBuffer()
        ..write("try {\n")
        ..write(new IndentedStringBuffer(node.body.accept(this)).indent())
        ..write("}");
    if (node.catchClauses.isNotEmpty) {
      assert(node.catchClauses.length == 1);
      var catchClause = node.catchClauses.first;
      assert(catchClause.onKeyword == null);
      var catchVisitor = new BlockVisitor(cls)
          ..errorVariableName = catchClause.exceptionParameter.name;
      var exceptionVar = catchClause.exceptionParameter.name;
      var stackParam = catchClause.stackTraceParameter;
      var catchOutput = new IndentedStringBuffer();
      if (stackParam != null) {
        catchOutput.writeln("var ${stackParam.name} = ${exceptionVar}.stack;");
      }
      catchOutput.write(catchClause.body.accept(catchVisitor));
      output
          ..write(" catch (${exceptionVar}) {\n")
          ..write(catchOutput.indent())
          ..write("}");
    }
    if (node.finallyBlock != null) {
      output..write(" finally {\n")
            ..write(new IndentedStringBuffer(node.finallyBlock.accept(this)).indent())
            ..write("}");
    }
    return output;
  }

  visitVariableDeclaration(VariableDeclaration node) {
    _checkDeclarationShadowing(node.name.toString());
    var initializer = node.initializer == null ? "null" : node.initializer.accept(this);
    return "${node.name.toString()} = $initializer";
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
        ..write(new IndentedStringBuffer(node.body.accept(this)).indent())
        ..write("}");
    return output;
  }
}
