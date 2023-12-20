module CST2AST

import AST;
import Boolean;
import ParseTree;
import String;
import Syntax;

/*
 * Implement a mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 *
 * - Use switch to do case distinction with concrete patterns (like in Hack your JS)
 * - Map regular CST arguments (e.g., *, +, ?) to lists
 *   (NB: you can iterate over * / + arguments using `<-` in comprehensions or for-loops).
 * - Map lexical nodes to Rascal primitive types (bool, int, str)
 * - See the ref example on how to obtain and propagate source locations.
 */

AForm cst2ast(start[Form] sf) = cst2ast(sf.top);

AForm cst2ast(Form f) {
  return form(id("<f.name>", src=f.name.src), [cst2ast(q) | q <- f.questions], src=f.src);
}

default AQuestion cst2ast(Question q) {
  switch (q) {
    case (Question) `<Prompt p> <Answer a>`:
      return question(prompt("<p>", src=p.src), cst2ast(a), src=q.src);

    case (Question) `<IfStatement ifStatement>`:
      return conditionalQuestion(cst2ast(ifStatement), src=q.src);

    default:
      throw "Unhandled question: <q>";
  }
}

default AAnswer cst2ast(Answer a) {
  switch (a) {
    case (Answer) `<Id i> : <Type t>`:
      return answer(id("<i>", src=i.src), cst2ast(t), src=a.src);

    case (Answer) `<Id i> : <Type t> = <Expr expr>`:
      return answerExpresion(id("<i>", src=i.src), cst2ast(t), cst2ast(expr), src=a.src);

    default:
      throw "Unhandled answer: <a>";
  }
}

AExpr cst2ast(Expr e) {
  switch (e) {
    case (Expr) `<Id x>`:
      return ref(id("<x>", src=x.src), src=x.src);
    case (Expr) `<Bool b>`:
      return boolLiteral(fromString("<b>"), src=b.src);
    case (Expr) `<Int i>`:
      return intLiteral(toInt("<i>"), src=i.src);
    case (Expr) `<Str s>`:
      return strLiteral("<s>", src=s.src);
    case (Expr) `( <Expr e1> )`:
      return singleExpr(cst2ast(e1), src=e.src);
    case (Expr) `<Expr e1> * <Expr e2>`:
      return mul(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr) `<Expr e1> / <Expr e2>`:
      return div(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr) `<Expr e1> - <Expr e2>`:
      return sub(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr) `<Expr e1> + <Expr e2>`:
      return add(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr) `<Expr e1> \< <Expr e2>`:
      return lt(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr) `<Expr e1> \<= <Expr e2>`:
      return le(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr) `<Expr e1> \> <Expr e2>`:
      return gt(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr) `<Expr e1> \>= <Expr e2>`:
      return ge(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr) `<Expr e1> == <Expr e2>`:
      return eqq(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr) `<Expr e1> != <Expr e2>`:
      return neq(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr) `<Expr e1> && <Expr e2>`:
      return and(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr) `<Expr e1> || <Expr e2>`:
      return or(cst2ast(e1), cst2ast(e2), src=e.src);

    default: throw "Unhandled expression: <e>";
  }
}

default AIfStatement cst2ast(IfStatement i) {
  switch (i) {
    case (IfStatement) `if ( <Expr expr> ) { <Question* qs> }`:
      return if1(cst2ast(expr), [cst2ast(q) | q <- qs], src=i.src);

    case (IfStatement) `if ( <Expr expr> ) { <Question* qs> } <ElseStatement e>`:
      return if2(cst2ast(expr), [cst2ast(q) | q <- qs], cst2ast(e), src=i.src);

    default:
      throw "Unhandled if statement: <i>";
  }
}

default AElseStatement cst2ast(ElseStatement e) {
  switch (e) {
    case (ElseStatement) `else { <Question* qs> }`:
      return else1([cst2ast(q) | q <- qs], src=e.src);

    case (ElseStatement) `else <IfStatement i>`:
      return else2(cst2ast(i), src=e.src);

    default:
      throw "Unhandled else statement: <e>";
  }
}

default AType cst2ast(Type t) {
  switch (t) {
    case (Type) `boolean`:
      return booleanType(src=t.src);
    case (Type) `integer`:
      return integerType(src=t.src);
    case (Type) `string`:
      return stringType(src=t.src);

    default:
      throw "Unhandled type: <t>";
  }
}
