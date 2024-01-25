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

alias Scope = tuple[list[str] names, list[loc] locs];

alias ScopeDef = tuple[Scope scope, UseDef useDef];

// the reference graph
alias RefGraph = tuple[
  Use uses,
  Def defs,
  UseDef useDef
];

Scope push(AId elem, Scope scope) {
  scope.names = push(elem.name, scope.names);
  scope.locs = push(elem.src, scope.locs);
  return scope;
}

int indexOf(Scope scope, str elem) {
  return indexOf(scope.names, elem);
}

AId elementAt(Scope scope, int index) {
  str name = elementAt(scope.names, index);
  loc src = elementAt(scope.locs, index);
  return id(name, src=src);
}

RefGraph resolve(AForm f) {
  Use us = uses(f);
  Def ds = defs(f);
  ScopeDef scopeDef = <<[], []>, {}>;
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
      Scope scopeTmp = scopeDef.scope;
      for (AQuestion q <- questions) {
        scopeDef = resolve(q, scopeDef);
      }
      scopeDef.scope = scopeTmp;
      scopeDef = resolve(elseStatement, scopeDef);
      scopeDef.scope = scopeTmp;
    }
    case if1(AExpr expr, list[AQuestion] questions): {
      scopeDef = addToUseDef(expr, scopeDef);
      Scope scopeTmp = scopeDef.scope;
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
  for (/ref(AId idUse) := e) {
    int index = indexOf(scopeDef.scope, idUse.name);
    if (index != -1) {
      AId idDef = elementAt(scopeDef.scope, index);
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
