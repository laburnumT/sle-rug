module AST

/*
 * Define Abstract Syntax for QL
 *
 * - complete the following data types
 * - make sure there is an almost one-to-one correspondence with the grammar
 */

data AForm(loc src = |tmp:///|)
  = form(AId name, list[AQuestion] questions)
  ;

data APrompt(loc src = |tmp:///|)
  = prompt(str string)
  ;

data AQuestion(loc src = |tmp:///|)
  = question(APrompt questionTxt, AAnswer answer)
  | conditionalQuestion(AIfStatement ifStatement)
  ;

data AAnswer(loc src = |tmp:///|)
  = answer(AId id, AType typeName)
  | answerExpression(AId id, AType typeName, AExpr expr)
  ;

data AExpr(loc src = |tmp:///|)
  = ref(AId id)
  | boolLiteral(bool boolVal)
  | intLiteral(int intVal)
  | strLiteral(str strVal)
  | singleExpr(AExpr expr)
  | mul(AExpr exprLeft, AExpr exprRight)
  | div(AExpr exprLeft, AExpr exprRight)
  | sub(AExpr exprLeft, AExpr exprRight)
  | add(AExpr exprLeft, AExpr exprRight)
  | lt(AExpr exprLeft, AExpr exprRight)
  | le(AExpr exprLeft, AExpr exprRight)
  | gt(AExpr exprLeft, AExpr exprRight)
  | ge(AExpr exprLeft, AExpr exprRight)
  | eqq(AExpr exprLeft, AExpr exprRight)
  | neq(AExpr exprLeft, AExpr exprRight)
  | and(AExpr exprLeft, AExpr exprRight)
  | or(AExpr exprLeft, AExpr exprRight)
  ;

data AIfStatement(loc src = |tmp:///|)
  = if1(AExpr expr, list[AQuestion] questions)
  | if2(AExpr expr, list[AQuestion] questions, AElseStatement elseStatement)
  ;

data AElseStatement(loc src = |tmp:///|)
  = else1(list[AQuestion] questions)
  | else2(AIfStatement ifStatement)
  ;

data AId(loc src = |tmp:///|)
  = id(str name);

data AType(loc src = |tmp:///|)
  = booleanType()
  | integerType()
  | stringType()
  ;
