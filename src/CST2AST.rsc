module CST2AST

import Syntax;
import AST;
import ParseTree;
import Boolean;
import String;

/*
 * Implement a mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 *
 * - Use switch to do case distinction with concrete patterns (like in Hack your JS) 
 * - Map regular CST arguments (e.g., *, +, ?) to lists 
 *   (NB: you can iterate over * / + arguments using `<-` in comprehensions or for-loops).
 * - Map lexical nodes to Rascal primitive types (bool, int, str)
 * - See the ref example on how to obtain and propagate source locations.
 */

AForm cst2ast(start[Form] sf) {
  Form f = sf.top; // remove layout before and after form
  return form(id(""), [ ], src=f.src); 
}

AForm cst2ast((Form)`form <Id name> { <Question* questions> }`)
= form(cst2ast(name), [cst2ast(q) | Question q <- questions]);

default AQuestion cst2ast(Question q){
  switch (q) {
    case (Question)`<Str question_txt> <Answer answer>`: return simple_question(cst2ast(question_txt), cst2ast(answer), src=q.src);
    case (Question)`<If_statement if_statement>`: return conditional_question(cst2ast(if_statement), src=q.src);
    
    default: throw "Unhandled question: <q>";
  }
}

default AAnswer cst2ast(Answer a){
  switch (a) {
    case (Answer)`<Id id> : <Type type_name>`: return simple_answer(cst2ast(id), cst2ast(type_name), src=a.src);
    case (Answer)`<Id id> : <Type type_name> = <Expr expr>`: return expression_answer(cst2ast(id), cst2ast(type_name), cst2ast(expr), src=a.src);
    
    default: throw "Unhandled answer: <a>";
  }
}

AExpr cst2ast(Expr e) {
  switch (e) {
    case (Expr)`<Id x>`: return ref(id("<x>", src=x.src), src=x.src);
    case (Expr)`<Bool b>`: return boolLiteral(fromString("<b>"), src=b.src);
    case (Expr)`<Int i>`: return intLiteral(toInt("<i>"), src=i.src);
    case (Expr)`<Str s>`: return strLiteral("<s>", src=s.src);
    case (Expr)`( <Expr e1> )`: return single_expr(cst2ast(e1), src=e.src);
    case (Expr)`<Expr e1> * <Expr e2>`: return mul(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr)`<Expr e1> / <Expr e2>`: return div(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr)`<Expr e1> - <Expr e2>`: return sub(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr)`<Expr e1> + <Expr e2>`: return add(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr)`<Expr e1> \< <Expr e2>`: return lt(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr)`<Expr e1> \<= <Expr e2>`: return le(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr)`<Expr e1> \> <Expr e2>`: return gt(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr)`<Expr e1> \>= <Expr e2>`: return ge(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr)`<Expr e1> == <Expr e2>`: return eq(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr)`<Expr e1> != <Expr e2>`: return neq(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr)`<Expr e1> && <Expr e2>`: return and(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr)`<Expr e1> || <Expr e2>`: return or(cst2ast(e1), cst2ast(e2), src=e.src);

    default: throw "Unhandled expression: <e>";
  }
}

AIf_statement cst2ast(If_statement if_statement){
  switch (if_statement) {
    case (If_statement)`if ( <Expr expr> ) { <Question* questions> }`: return if1(cst2ast(expr), [cst2ast(q) | Question q <- questions], src=if_statement.src);
    case (If_statement)`if ( <Expr expr> ) { <Question* questions> } <Else_statement else_statement>`: return if2(cst2ast(expr), [cst2ast(q) | Question q <- questions], cst2ast(else_statement), src=if_statement.src);
    
    default: throw "Unhandled if_statement: <if_statement>";
  }
}

AElse_statement cst2ast(Else_statement else_statement){
  switch (else_statement) {
    case (Else_statement)`else { <Question* questions> }`: return else1([cst2ast(q) | Question q <- questions], src=else_statement.src);
    case (Else_statement)`else <If_statement if_statement>`: return else2(cst2ast(if_statement), src=else_statement.src);
    
    default: throw "Unhandled else_statement: <else_statement>";
  }
}

default AType cst2ast(Type t) {
  switch (t) {
    case (Type)`boolean`: return booleanType(src=t.src);
    case (Type)`integer`: return integerType(src=t.src);
    case (Type)`string`: return stringType(src=t.src);
    
    default: throw "Unhandled type: <t>";
  }
}

AId cst2ast(Id x) = id("<x>");

AStr cst2ast(Str x) = _str("<x>");