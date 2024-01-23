module Test

import AST;
import Check;
import Compile;
import CST2AST;
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
}
