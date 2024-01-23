module Eval

import AST;

/*
 * Implement big-step semantics for QL
 */

// NB: Eval may assume the form is type- and name-correct.

// Semantic domain for expressions (values)
data Value
  = vint(int n)
  | vbool(bool b)
  | vstr(str s)
  ;

// The value environment
alias VEnv = map[str name, Value \value];

// Modeling user input
data Input
  = input(str question, Value \value);

Value getDefaultValue(AType typeName) {
  switch (typeName) {
    case booleanType(): {
      return vbool(false);
    }
    case integerType(): {
      return vint(0);
    }
    case stringType(): {
      return vstr("");
    }
  }
  throw "Unsupported type <typeName>";
}

// produce an environment which for each question has a default value
// (e.g. 0 for int, "" for str etc.)
VEnv initialEnv(AForm f) {
  VEnv venv = ();

  for (AQuestion q <- f.questions) {
    venv = initialEnv(q, venv);
  }

  return venv;
}

VEnv initialEnv(AQuestion q, VEnv venv) {
  switch (q) {
    case question(_, AAnswer answer): {
      venv = initialEnv(answer, venv);
    }
    case conditionalQuestion(AIfStatement ifStatement): {
      venv = initialEnv(ifStatement, venv);
    }
    default: {
      throw "Unsupported question <q>";
    }  
  }

  return venv;
}

VEnv initialEnv(AAnswer answer, VEnv venv) {
  switch (answer) {
    case answer(AId id, AType typeName): {
      venv[id.name] = getDefaultValue(typeName);
    }
    case answerExpression(AId id, AType typeName, _): {
      venv[id.name] = getDefaultValue(typeName);
    }  
    default: {
      throw "Unsupported answer <answer>";
    }
  }

  return venv;
}

VEnv initialEnv(AIfStatement ifStatement, VEnv venv) {
  switch (ifStatement) {
    case if1(_, list[AQuestion] questions): {
      for (AQuestion q <- questions) {
        venv = initialEnv(q, venv);
      }
    }
    case if2(_, list[AQuestion] questions, AElseStatement elseStatement): {
      for (AQuestion q <- questions) {
        venv = initialEnv(q, venv);
      }

      venv = initialEnv(elseStatement, venv);
    }
    default: {
      throw "Unsupported if statement <ifStatement>";
    }
  }

  return venv;
}

VEnv initialEnv(AElseStatement elseStatement, VEnv venv){
  switch (elseStatement){
    case else1(list[AQuestion] questions): {
      for (AQuestion q <- questions) {
        venv = initialEnv(q, venv);
      }
    }
    case else2(AIfStatement ifStatement): {
      venv = initialEnv(ifStatement, venv);
    }
    default: {
      throw "Unsupported else statement <elseStatement>";
    }
  }

  return venv;
}

// Because of out-of-order use and declaration of questions
// we use the solve primitive in Rascal to find the fixpoint of venv.
VEnv eval(AForm f, Input inp, VEnv venv) {
  return solve (venv) {
    venv = evalOnce(f, inp, venv);
  }
}

VEnv evalOnce(AForm f, Input inp, VEnv venv) {
  venv[inp.question] = inp.\value;
 
  for (AQuestion q <- f.questions) {
    venv = eval(q, inp, venv);
  }

  return venv;
}

// Evaluate conditions for branching,
// evaluate inp and computed questions to return updated VEnv
VEnv eval(AQuestion q, Input inp, VEnv venv) {
  switch (q) {
    case question(_, AAnswer answer): {
      venv = eval(answer, inp, venv);
    }
    case conditionalQuestion(AIfStatement ifStatement): {
      venv = eval(ifStatement, inp, venv);
    }
    default: {
      throw "Unsupported question <q>";
    }
  }

  return venv;
}

VEnv eval(AAnswer answer, Input inp, VEnv venv) {
  switch (answer) {
    case answer(_, _): { 
      ;
    }
    case answerExpression(AId id, _, AExpr expr): {
      venv[id.name] = eval(expr, venv);
    }
    default: {
      throw "Unsupported answer <answer>";
    }
  }

  return venv;
}

VEnv eval(AIfStatement ifStatement, Input inp, VEnv venv) {
  switch (ifStatement) {
    case if1(AExpr expr, list[AQuestion] questions): {
      if (eval(expr, venv) == vbool(true)) {
        for (AQuestion q <- questions) {
          venv = eval(q, inp, venv);
        }
      }
    }
    case if2(AExpr expr, list[AQuestion] questions, AElseStatement elseStatement): {
      if (eval(expr, venv) == vbool(true)) {
        for (AQuestion q <- questions) {
          venv = eval(q, inp, venv);
        }
      } else {
        venv = eval(elseStatement, inp, venv);
      }
    }
    default: {
      throw "Unsupported if statement <ifStatement>";
    }
  }

  return venv;
}

VEnv eval(AElseStatement elseStatement, Input inp, VEnv venv) {
  switch (elseStatement) {
    case else1(list[AQuestion] questions): {
      for (AQuestion q <- questions) {
        venv = eval(q, inp, venv);
      }
    }
    case else2(AIfStatement ifStatement): {
      venv = eval(ifStatement, inp, venv);
    }
    default: {
      throw "Unsupported else statement <elseStatement>";
    }
  }

  return venv;
}

Value eval(AExpr e, VEnv venv) {
  switch (e) {
    case ref(id(str x)): {
      return venv[x];
    }
    case boolLiteral(bool b): {
      return vbool(b);
    }
    case intLiteral(int i): {
      return vint(i);
    }
    case strLiteral(str s): {
      return vstr(s);
    }
    case singleExpr(AExpr expr): {
      return eval(expr, venv);
    }
    case mul(AExpr exprLeft, AExpr exprRight): {
      return vint(eval(exprLeft, venv).n * eval(exprRight, venv).n);
    }
    case div(AExpr exprLeft, AExpr exprRight): {
      return vint(eval(exprLeft, venv).n / eval(exprRight, venv).n);
    }
    case sub(AExpr exprLeft, AExpr exprRight): {
      return vint(eval(exprLeft, venv).n - eval(exprRight, venv).n);
    }
    case add(AExpr exprLeft, AExpr exprRight): {
      return vint(eval(exprLeft, venv).n + eval(exprRight, venv).n);
    }
    case lt(AExpr exprLeft, AExpr exprRight): {
      return vbool(eval(exprLeft, venv).n < eval(exprRight, venv).n);
    }
    case le(AExpr exprLeft, AExpr exprRight): {
      return vbool(eval(exprLeft, venv).n <= eval(exprRight, venv).n);
    }
    case gt(AExpr exprLeft, AExpr exprRight): {
      return vbool(eval(exprLeft, venv).n > eval(exprRight, venv).n);
    }
    case ge(AExpr exprLeft, AExpr exprRight): {
      return vbool(eval(exprLeft, venv).n >= eval(exprRight, venv).n);
    }
    case eqq(AExpr exprLeft, AExpr exprRight): {
      return evalEquality(eval(exprLeft, venv), eval(exprRight, venv), true);
    }
    case neq(AExpr exprLeft, AExpr exprRight): {
      return evalEquality(eval(exprLeft, venv), eval(exprRight, venv), false);
    }
    case and(AExpr exprLeft, AExpr exprRight): {
      return vbool(eval(exprLeft, venv).b && eval(exprRight, venv).b);
    }
    case or(AExpr exprLeft, AExpr exprRight): {
      return vbool(eval(exprLeft, venv).b || eval(exprRight, venv).b);
    }
    default: {
      throw "Unsupported expression <e>";
    }
  }
}

Value evalEquality(Value leftValue, Value rightValue, bool isEqual) {
    if (leftValue is vint && rightValue is vint) {
        return vbool((isEqual && leftValue.n == rightValue.n) || (!isEqual && leftValue.n != rightValue.n));
    } else if (leftValue is vbool && rightValue is vbool) {
        return vbool((isEqual && leftValue.b == rightValue.b) || (!isEqual && leftValue.b != rightValue.b));
    } else if (leftValue is vstr && rightValue is vstr) {
        return vbool((isEqual && leftValue.s == rightValue.s) || (!isEqual && leftValue.s != rightValue.s));
    } else {
        throw "Type mismatch or unsupported type in comparison";
    }
}
