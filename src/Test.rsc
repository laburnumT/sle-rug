module Test

import AST;
import Check;
import Compile;
import CST2AST;
import Eval;
import IO;
import Message;
import ParseTree;
import Resolve;
import Syntax;

void testMain(loc inputFile) {
  parsed = parse(#Form, inputFile);
  ast = cst2ast(parsed);
  RefGraph g = resolve(ast);
  TEnv tenv = collect(ast);
  set[Message] msgs = check(ast, tenv, g.useDef);
  compile(ast);
  map[str, value] venvMap = ("hasSoldHouse": true, "sellingPrice": 300, "privateDebt": 20);
  VEnv env = initialEnv(ast);
  for(venvName <- venvMap) {
    Value val = getValue(venvMap[venvName]);
    env = eval(ast, input(venvName, val), env);
  }
}

Value getValue(value val) {
  switch (val) {
    case int n: {
      return vint(n);
    }
    case bool b: {
      return vbool(b);
    }
    case str s: {
      return vstr(s);
    }
    default: {
      throw "Unsupported value <val>";
    }
  }
}
