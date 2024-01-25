module Resolve

import AST;
import List;

/*
 * Name resolution for QL
 */


// modeling declaring occurrences of names
alias Def = rel[str name, loc def];

// modeling use occurrences of names
alias Use = rel[loc use, str name];

alias UseDef = rel[loc use, loc def];

alias ScopeDef = tuple[list[AId] scope, UseDef useDef];

// the reference graph
alias RefGraph = tuple[
  Use uses,
  Def defs,
  UseDef useDef
];

RefGraph resolve(AForm f) {
  Use us = uses(f);
  Def ds = defs(f);
  ScopeDef scopeDef = <[], {}>;
  scopeDef.scope = push(f.name, scopeDef.scope);
  for (AQuestion q <- f.questions) {
    scopeDef = resolve(q, scopeDef);
  }
  return <us, ds, scopeDef.useDef>;
}

ScopeDef resolve(AQuestion q, ScopeDef scopeDef) {
  switch (q) {
    case conditionalQuestion(AIfStatement ifStatement): {
      scopeDef = resolve(ifStatement, scopeDef);
    }
    case question(_, AAnswer answer): {
      scopeDef = resolve(answer, scopeDef);
    }
  }
  return scopeDef;
}

ScopeDef resolve(AAnswer a, ScopeDef scopeDef) {
  switch (a) {
    case answerExpression(AId idDef, _, AExpr expr): {
      scopeDef.scope = push(idDef, scopeDef.scope);
      scopeDef = addToUseDef(expr, scopeDef);
    }
    case answer(AId idDef, _): {
      scopeDef.scope = push(idDef, scopeDef.scope);
    }
  }
  return scopeDef;
}

ScopeDef resolve(AIfStatement ifStatement, ScopeDef scopeDef) {
  switch (ifStatement) {
    case if2(AExpr expr, list[AQuestion] questions, AElseStatement elseStatement): {
      scopeDef = addToUseDef(expr, scopeDef);
      list[AId] scopeTmp = scopeDef.scope;
      for (AQuestion q <- questions) {
        scopeDef = resolve(q, scopeDef);
      }
      scopeDef.scope = scopeTmp;
      scopeDef = resolve(elseStatement, scopeDef);
      scopeDef.scope = scopeTmp;
    }
    case if1(AExpr expr, list[AQuestion] questions): {
      scopeDef = addToUseDef(expr, scopeDef);
      list[AId] scopeTmp = scopeDef.scope;
      for (AQuestion q <- questions) {
        scopeDef = resolve(q, scopeDef);
      }
      scopeDef.scope = scopeTmp;
    }
  }
  return scopeDef;
}

ScopeDef resolve(AElseStatement elseStatement, ScopeDef scopeDef) {
  switch (elseStatement) {
    case else2(AIfStatement ifStatement): {
      scopeDef = resolve(ifStatement, scopeDef);
    }
    case else1(list[AQuestion] questions): {
      for (AQuestion q <- questions) {
        scopeDef = resolve(q, scopeDef);
      }
    }
  }
  return scopeDef;
}

ScopeDef addToUseDef(AExpr e, ScopeDef scopeDef) {
  for (AId idDef <- scopeDef.scope) {
    for (/ref(AId idUse) := e) {
      if (idUse.name == idDef.name) {
        scopeDef.useDef += {<idUse.src, idDef.src>};
      }
    }
  }
  return scopeDef;
}

Use uses(AForm f) {
  return {<i.src, i.name> | /ref(AId i) := f};
}

Def defs(AForm f) {
  Def formDef = {<i.name, i.src> | /form(AId i, _) := f};
  Def answerDef = {<i.name, i.src> | /answer(AId i, _) := f};
  Def answerExprDef = {<i.name, i.src> | /answerExpression(AId i, _, _) := f};

  return formDef + answerDef + answerExprDef;
}
