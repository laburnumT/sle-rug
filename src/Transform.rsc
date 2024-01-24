module Transform

import AST;
import ParseTree;
import Resolve;
import Syntax;

/*
 * Transforming QL forms
 */


/* Normalization:
 *  wrt to the semantics of QL the following
 *     q0: "" int;
 *     if (a) {
 *        if (b) {
 *          q1: "" int;
 *        }
 *        q2: "" int;
 *      }
 *
 *  is equivalent to
 *     if (true) q0: "" int;
 *     if (true && a && b) q1: "" int;
 *     if (true && a) q2: "" int;
 *
 * Write a transformation that performs this flattening transformation.
 *
 */

AForm flatten(AForm f) {
  list[AQuestion] flattened = [];
  for (AQuestion q <- f.questions) {
    flattened += flatten(q, boolLiteral(true));
  }
  f.questions = flattened;
  return f;
}

list[AQuestion] flatten(AQuestion q, AExpr e) {
  switch (q) {
    case question(_, _): {
      return [conditionalQuestion(if1(e, [q]))];
    }
    case conditionalQuestion(AIfStatement ifStatement): {
      return flatten(ifStatement, e);
    }
  }
  throw "Failed to flatten: <q>";
}

list[AQuestion] flatten(AIfStatement ifStatement, AExpr e) {
  list[AQuestion] ret = [];
  switch (ifStatement) {
    case if2(AExpr expr, list[AQuestion] questions, AElseStatement elseStatement): {
      for (AQuestion q <- questions) {
        ret += flatten(q, and(e, expr));
      }
      ret += flatten(elseStatement, and(not(expr), e));
    }
    case if1(AExpr expr, list[AQuestion] questions): {
      for (AQuestion q <- questions) {
        ret += flatten(q, and(e, expr));
      }
    }
  }
  return ret;
}

list[AQuestion] flatten(AElseStatement elseStatement, AExpr e) {
  list[AQuestion] ret = [];
  switch (elseStatement) {
    case else2(AIfStatement ifStatement): {
      ret += flatten(ifStatement, e);
    }
    case else1(list[AQuestion] questions): {
      for (AQuestion q <- questions) {
        ret += flatten(q, e);
      }
    }
  }
  return ret;
}

/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 */

start[Form] rename(start[Form] f, loc useOrDef, str newName, UseDef useDef) {
  loc defLoc = getDef(useOrDef, useDef);
  set[loc] equiv = {defLoc};
  for (<loc useLoc, defLoc> <- useDef) {
    equiv += useLoc;
  }
  return visit(f) {
    case Id x => [Id]newName
      when x.src in equiv
  }
}

loc getDef(loc useOrDef, UseDef useDef) {
  if (<useOrDef, loc defLoc> <- useDef) {
    return defLoc;
  }
  return useOrDef;
}
