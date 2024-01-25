module Check

import AST;
import Resolve;
import Message; // see standard library

data Type
  = tint()
  | tbool()
  | tstr()
  | tunknown()
  ;

Type convert(AType t) {
  switch(t) {
    case stringType(): {
      return tstr();
    }
    case integerType(): {
      return tint();
    }
    case booleanType(): {
      return tbool();
    }
    default:
      return tunknown();
  }
}

// the type environment consisting of defined questions in the form
alias TEnv = rel[loc def, str name, str label, Type \type];

// To avoid recursively traversing the form, use the `visit` construct
// or deep match (e.g., `for (/question(...) := f) {...}` )
TEnv collect(AForm f) {
  return {
    <p.src, p.string, a.id.name, convert(a.typeName)>
      | /question(APrompt p, AAnswer a) := f
  };
}

set[Message] checkType(str label, Type \type, Type exprType, loc src,
                       TEnv tenv) {
  set[Message] msgs = {};
  if (exprType != \type) {
    msgs += error("Expression type does not match label type", src);
  }
  for (envQ <- tenv) {
    if (envQ.label == label) {
      if (envQ.\type != \type) {
        msgs += error("Redefinition of label with a different type", src);
      }
    }
  }
  return msgs;
}

set[Message] checkDuplicatePrompt(APrompt p, TEnv tenv) {
  set[Message] msgs = {};
  bool found = false;
  for (envQ <- tenv) {
    if (envQ.name == p.string) {
      if (found) {
        msgs += warning("Duplicate prompt", p.src);
      }
      found = true;
    }
  }
  return msgs;
}

set[Message] checkDuplicateLabel(AAnswer a, TEnv tenv) {
  set[Message] msgs = {};
  bool found = false;
  for (envQ <- tenv) {
    if (envQ.label == a.id.name) {
      if (found) {
        msgs += warning("Duplicate label", a.src);
      }
      found = true;
    }
  }
  return msgs;
}

set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  for (AQuestion q <- f.questions) {
    msgs += check(q, tenv, useDef);
  }
  return msgs;
}

set[Message] check(APrompt p, TEnv tenv, UseDef _) {
  set[Message] msgs = {};
  msgs += checkDuplicatePrompt(p, tenv);
  return msgs;
}

// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning
// - the declared type computed questions should match the type of the expression.
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  if (/conditionalQuestion(AIfStatement i) := q) {
    msgs += check(i, tenv, useDef);
  }
  else if (/question(APrompt p, AAnswer a) := q) {
    msgs += check(p, tenv, useDef);
    msgs += check(a, tenv, useDef);
  }
  return msgs;
}

set[Message] check(AAnswer a, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  msgs += checkDuplicateLabel(a, tenv);
  if (/answerExpression(AId id, AType typeName, AExpr expr) := a) {
    msgs += check(expr, tenv, useDef);
    msgs += checkType(id.name, convert(typeName), typeOf(expr, tenv, useDef),
                      a.src, tenv);
  }
  else if (/answer(AId id, AType typeName) := a) {
    msgs += checkType(id.name, convert(typeName), convert(typeName), a.src,
                      tenv);
  }
  return msgs;
}

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs),
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  switch (e) {
    case ref(AId x): {
      msgs += { error("Undeclared question", x.src) | useDef[x.src] == {} };
    }
    case singleExpr(AExpr expr): {
      msgs += check(expr, tenv, useDef);
    }
    case mul(AExpr exprLeft, AExpr exprRight): {
      msgs += check(exprLeft, tenv, useDef);
      msgs += check(exprRight, tenv, useDef);
      if (typeOf(exprLeft, tenv, useDef) != tint()) {
        msgs += error("Multiplication requires an integer", exprLeft.src);
      }
      if (typeOf(exprRight, tenv, useDef) != tint()) {
        msgs += error("Multiplication requires an integer", exprRight.src);
      }
    }
    case div(AExpr exprLeft, AExpr exprRight): {
      msgs += check(exprLeft, tenv, useDef);
      msgs += check(exprRight, tenv, useDef);
      if (typeOf(exprLeft, tenv, useDef) != tint()) {
        msgs += error("Division requires an integer", exprLeft.src);
      }
      if (typeOf(exprRight, tenv, useDef) != tint()) {
        msgs += error("Division requires an integer", exprRight.src);
      }
    }
    case sub(AExpr exprLeft, AExpr exprRight): {
      msgs += check(exprLeft, tenv, useDef);
      msgs += check(exprRight, tenv, useDef);
      if (typeOf(exprLeft, tenv, useDef) != tint()) {
        msgs += error("Subtraction requires an integer", exprLeft.src);
      }
      if (typeOf(exprRight, tenv, useDef) != tint()) {
        msgs += error("Subtraction requires an integer", exprRight.src);
      }
    }
    case add(AExpr exprLeft, AExpr exprRight): {
      msgs += check(exprLeft, tenv, useDef);
      msgs += check(exprRight, tenv, useDef);
      if (typeOf(exprLeft, tenv, useDef) != tint()) {
        msgs += error("Addition requires an integer", exprLeft.src);
      }
      if (typeOf(exprRight, tenv, useDef) != tint()) {
        msgs += error("Addition requires an integer", exprRight.src);
      }
    }
    case lt(AExpr exprLeft, AExpr exprRight): {
      msgs += check(exprLeft, tenv, useDef);
      msgs += check(exprRight, tenv, useDef);
      if (typeOf(exprLeft, tenv, useDef) != tint()) {
        msgs += error("Less than comparison requires an integer",
                      exprLeft.src);
      }
      if (typeOf(exprRight, tenv, useDef) != tint()) {
        msgs += error("Less than comparison requires an integer",
                      exprRight.src);
      }
    }
    case le(AExpr exprLeft, AExpr exprRight): {
      msgs += check(exprLeft, tenv, useDef);
      msgs += check(exprRight, tenv, useDef);
      if (typeOf(exprLeft, tenv, useDef) != tint()) {
        msgs += error("Less than or equal comparison requires an integer",
                      exprLeft.src);
      }
      if (typeOf(exprRight, tenv, useDef) != tint()) {
        msgs += error("Less than or equal comparison requires an integer",
                      exprRight.src);
      }
    }
    case gt(AExpr exprLeft, AExpr exprRight): {
      msgs += check(exprLeft, tenv, useDef);
      msgs += check(exprRight, tenv, useDef);
      if (typeOf(exprLeft, tenv, useDef) != tint()) {
        msgs += error("Greater than comparison requires an integer",
                      exprLeft.src);
      }
      if (typeOf(exprRight, tenv, useDef) != tint()) {
        msgs += error("Greater than comparison requires an integer",
                      exprRight.src);
      }
    }
    case ge(AExpr exprLeft, AExpr exprRight): {
      msgs += check(exprLeft, tenv, useDef);
      msgs += check(exprRight, tenv, useDef);
      if (typeOf(exprLeft, tenv, useDef) != tint()) {
        msgs += error("Greater than or equal comparison requires an integer",
                      exprLeft.src);
      }
      if (typeOf(exprRight, tenv, useDef) != tint()) {
        msgs += error("Greater than or equal comparison requires an integer",
                      exprRight.src);
      }
    }
    case eqq(AExpr exprLeft, AExpr exprRight): {
      msgs += check(exprLeft, tenv, useDef);
      msgs += check(exprRight, tenv, useDef);
      if (typeOf(exprLeft, tenv, useDef) != typeOf(exprRight, tenv, useDef)) {
        msgs += error("Equality comparison requires that types are equal",
                      e.src);
      }
    }
    case neq(AExpr exprLeft, AExpr exprRight): {
      msgs += check(exprLeft, tenv, useDef);
      msgs += check(exprRight, tenv, useDef);
      if (typeOf(exprLeft, tenv, useDef) != typeOf(exprRight, tenv, useDef)) {
        msgs += error("Inequality comparison requires that types are equal",
                      e.src);
      }
    }
    case and(AExpr exprLeft, AExpr exprRight): {
      msgs += check(exprLeft, tenv, useDef);
      msgs += check(exprRight, tenv, useDef);
      if (typeOf(exprLeft, tenv, useDef) != tbool()) {
        msgs += error("Logical and requires a boolean", exprLeft.src);
      }
      if (typeOf(exprRight, tenv, useDef) != tbool()) {
        msgs += error("Logical and requires a boolean", exprRight.src);
      }
    }
    case or(AExpr exprLeft, AExpr exprRight): {
      msgs += check(exprLeft, tenv, useDef);
      msgs += check(exprRight, tenv, useDef);
      if (typeOf(exprLeft, tenv, useDef) != tbool()) {
        msgs += error("Logical or requires a boolean", exprLeft.src);
      }
      if (typeOf(exprRight, tenv, useDef) != tbool()) {
        msgs += error("Logical or requires a boolean", exprRight.src);
      }
    }
  }
  return msgs;
}

set[Message] check(AIfStatement i, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  if (/if2(AExpr expr, list[AQuestion] questions, AElseStatement elseStatement) := i) {
    if (typeOf(expr, tenv, useDef) != tbool()) {
      msgs += error("Condition must be of boolean type.", expr.src);
    }
    msgs += check(expr, tenv, useDef);
    for (AQuestion q <- questions) {
      msgs += check(q, tenv, useDef);
    }
    msgs += check(elseStatement, tenv, useDef);
  }
  else if (/if1(AExpr expr, list[AQuestion] questions) := i) {
    if (typeOf(expr, tenv, useDef) != tbool()) {
      msgs += error("Condition must be of boolean type.", expr.src);
    }
    msgs += check(expr, tenv, useDef);
    for (AQuestion q <- questions) {
      msgs += check(q, tenv, useDef);
    }
  }
  return msgs;
}

set[Message] check(AElseStatement e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  if (/else2(AIfStatement i) := e) {
    msgs += check(i, tenv, useDef);
  }
  else if (/else1(list[AQuestion] questions) := e) {
    for (AQuestion q <- questions) {
      msgs += check(q, tenv, useDef);
    }
  }
  return msgs;
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(id(str label)): {
      if (<_, _, label, Type t> <- tenv) {
        return t;
      }
    }
    case boolLiteral(_): {
      return tbool();
    }
    case intLiteral(_): {
      return tint();
    }
    case strLiteral(_): {
      return tstr();
    }
    case singleExpr(AExpr expr): {
      return typeOf(expr, tenv, useDef);
    }
    case mul(_, _): {
      return tint();
    }
    case div(_, _): {
      return tint();
    }
    case sub(_, _): {
      return tint();
    }
    case add(_, _): {
      return tint();
    }
    case lt(_, _): {
      return tbool();
    }
    case le(_, _): {
      return tbool();
    }
    case gt(_, _): {
      return tbool();
    }
    case ge(_, _): {
      return tbool();
    }
    case eqq(_, _): {
      return tbool();
    }
    case neq(_, _): {
      return tbool();
    }
    case and(_, _): {
      return tbool();
    }
    case or(_, _): {
      return tbool();
    }
  }
  return tunknown();
}
