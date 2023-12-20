module Resolve

import AST;

/*
 * Name resolution for QL
 */


// modeling declaring occurrences of names
alias Def = rel[str name, loc def];

// modeling use occurrences of names
alias Use = rel[loc use, str name];

alias UseDef = rel[loc use, loc def];

// the reference graph
alias RefGraph = tuple[
  Use uses,
  Def defs,
  UseDef useDef
];

RefGraph resolve(AForm f) = <us, ds, us o ds>
  when Use us := uses(f), Def ds := defs(f);

Use uses(AForm f) {
  return {<i.src, i.name> | /ref(AId i) := f};
}

Def defs(AForm f) {
  formDef = {<i.name, i.src> | /form(AId i, _) := f};
  answerDef = {<i.name, i.src> | /answer(AId i, _) := f};
  answerExprDef = {<i.name, i.src> | /answerExpression(AId i, _, _) := f};

  return formDef + answerDef + answerExprDef;
}
