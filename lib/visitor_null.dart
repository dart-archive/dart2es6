import 'package:analyzer/analyzer.dart';
import 'writer.dart';

class NullVisitor implements AstVisitor {
  
  _complain(node) {
    print("Undefined in ${this.runtimeType}: ${node.runtimeType}");
    return new IndentedStringBuffer("<${node.runtimeType}>");
  }
  
  visitAdjacentStrings(AdjacentStrings node) => _complain(node);

  visitAnnotation(Annotation node) => _complain(node);

  visitArgumentList(ArgumentList node) => _complain(node);

  visitAsExpression(AsExpression node) => _complain(node);

  visitAssertStatement(AssertStatement assertStatement) => _complain(assertStatement);

  visitAssignmentExpression(AssignmentExpression node) => _complain(node);

  visitAwaitExpression(AwaitExpression node) => _complain(node);

  visitBinaryExpression(BinaryExpression node) => _complain(node);

  visitBlock(Block node) => _complain(node);

  visitBlockFunctionBody(BlockFunctionBody node) => _complain(node);

  visitBooleanLiteral(BooleanLiteral node) => _complain(node);

  visitBreakStatement(BreakStatement node) => _complain(node);

  visitCascadeExpression(CascadeExpression node) => _complain(node);

  visitCatchClause(CatchClause node) => _complain(node);

  visitClassDeclaration(ClassDeclaration node) => _complain(node);

  visitClassTypeAlias(ClassTypeAlias node) => _complain(node);

  visitComment(Comment node) => _complain(node);

  visitCommentReference(CommentReference node) => _complain(node);

  visitCompilationUnit(CompilationUnit node) => _complain(node);

  visitConditionalExpression(ConditionalExpression node) => _complain(node);

  visitConstructorDeclaration(ConstructorDeclaration node) => _complain(node);

  visitConstructorFieldInitializer(ConstructorFieldInitializer node) => _complain(node);

  visitConstructorName(ConstructorName node) => _complain(node);

  visitContinueStatement(ContinueStatement node) => _complain(node);

  visitDeclaredIdentifier(DeclaredIdentifier node) => _complain(node);

  visitDefaultFormalParameter(DefaultFormalParameter node) => _complain(node);

  visitDoStatement(DoStatement node) => _complain(node);

  visitDoubleLiteral(DoubleLiteral node) => _complain(node);

  visitEmptyFunctionBody(EmptyFunctionBody node) => _complain(node);

  visitEmptyStatement(EmptyStatement node) => _complain(node);

  visitExportDirective(ExportDirective node) => _complain(node);

  visitExpressionFunctionBody(ExpressionFunctionBody node) => _complain(node);

  visitExpressionStatement(ExpressionStatement node) => _complain(node);

  visitExtendsClause(ExtendsClause node) => _complain(node);

  visitFieldDeclaration(FieldDeclaration node) => _complain(node);

  visitFieldFormalParameter(FieldFormalParameter node) => _complain(node);

  visitForEachStatement(ForEachStatement node) => _complain(node);

  visitFormalParameterList(FormalParameterList node) => _complain(node);

  visitForStatement(ForStatement node) => _complain(node);

  visitFunctionDeclaration(FunctionDeclaration node) => _complain(node);

  visitFunctionDeclarationStatement(FunctionDeclarationStatement node) => _complain(node);

  visitFunctionExpression(FunctionExpression node) => _complain(node);

  visitFunctionExpressionInvocation(FunctionExpressionInvocation node) => _complain(node);

  visitFunctionTypeAlias(FunctionTypeAlias functionTypeAlias) => _complain(functionTypeAlias);

  visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) => _complain(node);

  visitHideCombinator(HideCombinator node) => _complain(node);

  visitIfStatement(IfStatement node) => _complain(node);

  visitImplementsClause(ImplementsClause node) => _complain(node);

  visitImportDirective(ImportDirective node) => _complain(node);

  visitIndexExpression(IndexExpression node) => _complain(node);

  visitInstanceCreationExpression(InstanceCreationExpression node) => _complain(node);

  visitIntegerLiteral(IntegerLiteral node) => _complain(node);

  visitInterpolationExpression(InterpolationExpression node) => _complain(node);

  visitInterpolationString(InterpolationString node) => _complain(node);

  visitIsExpression(IsExpression node) => _complain(node);

  visitLabel(Label node) => _complain(node);

  visitLabeledStatement(LabeledStatement node) => _complain(node);

  visitLibraryDirective(LibraryDirective node) => _complain(node);

  visitLibraryIdentifier(LibraryIdentifier node) => _complain(node);

  visitListLiteral(ListLiteral node) => _complain(node);

  visitMapLiteral(MapLiteral node) => _complain(node);

  visitMapLiteralEntry(MapLiteralEntry node) => _complain(node);

  visitMethodDeclaration(MethodDeclaration node) => _complain(node);

  visitMethodInvocation(MethodInvocation node) => _complain(node);

  visitNamedExpression(NamedExpression node) => _complain(node);

  visitNativeClause(NativeClause node) => _complain(node);

  visitNativeFunctionBody(NativeFunctionBody node) => _complain(node);

  visitNullLiteral(NullLiteral node) => _complain(node);

  visitParenthesizedExpression(ParenthesizedExpression node) => _complain(node);

  visitPartDirective(PartDirective node) => _complain(node);

  visitPartOfDirective(PartOfDirective node) => _complain(node);

  visitPostfixExpression(PostfixExpression node) => _complain(node);

  visitPrefixedIdentifier(PrefixedIdentifier node) => _complain(node);

  visitPrefixExpression(PrefixExpression node) => _complain(node);

  visitPropertyAccess(PropertyAccess node) => _complain(node);

  visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) => _complain(node);

  visitRethrowExpression(RethrowExpression node) => _complain(node);

  visitReturnStatement(ReturnStatement node) => _complain(node);

  visitScriptTag(ScriptTag node) => _complain(node);

  visitShowCombinator(ShowCombinator node) => _complain(node);

  visitSimpleFormalParameter(SimpleFormalParameter node) => _complain(node);

  visitSimpleIdentifier(SimpleIdentifier node) => _complain(node);

  visitSimpleStringLiteral(SimpleStringLiteral node) => _complain(node);

  visitStringInterpolation(StringInterpolation node) => _complain(node);

  visitSuperConstructorInvocation(SuperConstructorInvocation node) => _complain(node);

  visitSuperExpression(SuperExpression node) => _complain(node);

  visitSwitchCase(SwitchCase node) => _complain(node);

  visitSwitchDefault(SwitchDefault node) => _complain(node);

  visitSwitchStatement(SwitchStatement node) => _complain(node);

  visitSymbolLiteral(SymbolLiteral node) => _complain(node);

  visitThisExpression(ThisExpression node) => _complain(node);

  visitThrowExpression(ThrowExpression node) => _complain(node);

  visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) => _complain(node);

  visitTryStatement(TryStatement node) => _complain(node);

  visitTypeArgumentList(TypeArgumentList node) => _complain(node);

  visitTypeName(TypeName node) => _complain(node);

  visitTypeParameter(TypeParameter node) => _complain(node);

  visitTypeParameterList(TypeParameterList node) => _complain(node);

  visitVariableDeclaration(VariableDeclaration node) => _complain(node);

  visitVariableDeclarationList(VariableDeclarationList node) => _complain(node);

  visitVariableDeclarationStatement(VariableDeclarationStatement node) => _complain(node);

  visitWhileStatement(WhileStatement node) => _complain(node);

  visitWithClause(WithClause node) => _complain(node);

  visitYieldStatement(YieldStatement node) => _complain(node);
}
