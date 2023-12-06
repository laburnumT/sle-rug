module AST

/*
 * Define Abstract Syntax for QL
 *
 * - complete the following data types
 * - make sure there is an almost one-to-one correspondence with the grammar
 */

data AForm(loc src = |tmp:///|)
  = form(str name, list[AQuestion] questions)
  ;

data AQuestion(loc src = |tmp:///|)
  = simple_question(AType type_name, AAnswer answer)
  | conditional_question(AIf_statement if_statement)
  ;

data AAnswer(loc src = |tmp:///|)
  = simple_answer(AId id, AType type_name)
  | expression_answer(AId id, AType type_name, AExpr expr)
  ;

data AExpr(loc src = |tmp:///|)
  = ref(AId id)
  | boolLiteral(bool bool_val)
  | intLiteral(int int_val)
  | strLiteral(str str_val)
  | expr(AExpr expr_left, AExpr expr_right)
  ;

data AIf_statement(loc src = |tmp:///|)
  = if1(AExpr expr)
  | if2(AExpr expr, list[AQuestion] questions)
  ;

data AElse_statement(loc src = |tmp:///|)
  = else1(list[AQuestion] questions)
  | else2(AExpr expr, list[AQuestion] questions)
  ;

data AType(loc src = |tmp:///|)
  = booleanType()
  | integerType()
  | stringType()
  ;

data AId(loc src = |tmp:///|)
  = id(str name);