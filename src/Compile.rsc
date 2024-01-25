module Compile

import AST;
import Check;
import IO;
import lang::html::AST; // see standard library
import lang::html::IO;
import Resolve;

/*
 * Implement a compiler for QL to HTML and Javascript
 *
 * - assume the form is type- and name-correct
 * - separate the compiler in two parts form2html and form2js producing 2 files
 * - use string templates to generate Javascript
 * - use the HTMLElement type and the `str writeHTMLString(HTMLElement x)` function to format to string
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - map booleans to checkboxes, strings to textfields, ints to numeric text fields
 * - be sure to generate uneditable widgets for computed questions!
 * - if needed, use the name analysis to link uses to definitions
 */

alias ConditionalMap = rel[AExpr expr, int conditionalId];

ConditionalMap condMap = {};
int conditionalQuestionCnt = 0;

loc getDef(loc useOrDef, UseDef useDef) {
  if (<useOrDef, loc defLoc> <- useDef) {
    return defLoc;
  }
  return useOrDef;
}

str mangleId(AId id, RefGraph rg) {
  loc src = getDef(id.src, rg.useDef);
  return "<id.name>_<md5Hash(src)>";
}

void compile(AForm f) {
  condMap = {};
  conditionalQuestionCnt = 0;
  RefGraph rg = resolve(f);
  writeFile(f.src[extension="html"].top, writeHTMLString(form2html(f, rg)));
  writeFile(f.src[extension="js"].top, form2js(f, rg));
}

HTMLElement form2html(AForm f, RefGraph rg) {
  list[HTMLElement] elements = [];
  for (AQuestion q <- f.questions) {
    elements += question2html(q, rg);
  }
  elements += script([], src="<f.src[extension="js"].file>");
  return html(elements);
}

HTMLElement question2html(AQuestion q, RefGraph rg) {
  list[HTMLElement] elements = [];
  str class = "";
  str id = "";
  switch (q) {
    case conditionalQuestion(AIfStatement ifStatement): {
      class = "conditionalQuestion";
      id = "conditionalQuestion<conditionalQuestionCnt>";
      elements += if2html(ifStatement, rg);
    }
    case question(APrompt prompt, AAnswer answer): {
      class = "question";
      id = "<mangleId(answer.id, rg)>iv";
      elements += label([\data(prompt.string)], \for=answer.id.name);
      elements += questionField(mangleId(answer.id, rg), answer.typeName);
    }
  }
  return div(elements, class=class, id=id);
}

HTMLElement if2html(AIfStatement ifStatement, RefGraph rg) {
  list[HTMLElement] elements = [];
  int conditionalId = conditionalQuestionCnt;
  conditionalQuestionCnt += 1;
  switch (ifStatement) {
    case if2(AExpr expr, list[AQuestion] questions, AElseStatement elseStatement): {
      condMap += <expr, conditionalId>;
      list[HTMLElement] ifQuestions = [];
      for (AQuestion q <- questions) {
        ifQuestions += question2html(q, rg);
      }
      elements += div(ifQuestions, id="ifStatement<conditionalId>");
      elements += else2html(elseStatement, conditionalId, rg);
    }
    case if1(AExpr expr, list[AQuestion] questions): {
      condMap += <expr, conditionalId>;
      list[HTMLElement] ifQuestions = [];
      for (AQuestion q <- questions) {
        ifQuestions += question2html(q, rg);
      }
      elements += div(ifQuestions, id="ifStatement<conditionalId>");
    }
  }
  return div(elements);
}

HTMLElement else2html(AElseStatement elseStatement, int conditionalId, RefGraph rg) {
  list[HTMLElement] elements = [];
  switch (elseStatement) {
    case else2(AIfStatement ifStatement): {
      elements += if2html(ifStatement, rg);
    }
    case else1(list[AQuestion] questions): {
      for (AQuestion q <- questions) {
        elements += question2html(q, rg);
      }
    }
  }
  return div(elements, id="elseStatement<conditionalId>");
}

HTMLElement questionField(str id, AType t) {
  str fieldType = "";
  str placeholder = "";
  switch (t) {
    case booleanType(): {
      fieldType = "checkbox";
      placeholder = "false";
    }
    case integerType(): {
      fieldType = "number";
      placeholder = "0";
    }
    case stringType(): {
      fieldType = "text";
      placeholder = "";
    }
  }
  return input(id=id, \type=fieldType, placeholder=placeholder, oninput="refresh(this);");
}

str access2js(AType t) {
  switch (t) {
    case booleanType(): {
      return "checked";
    }
    default: {
      return "value";
    }
  }
}

str access2js(Type t) {
  switch (t) {
    case tbool(): {
      return "checked";
    }
    default: {
      return "value";
    }
  }
}

str defaultValues(AType t) {
  switch (t) {
    case booleanType(): {
      return "false";
    }
    case integerType(): {
      return "0";
    }
    case stringType(): {
      return "\"\"";
    }
  }
  return "\"\"";
}

str initVals(AForm f, RefGraph rg) {
  str ret = "";
  for (def <- rg.defs) {
    ret += "var <mangleId(id(def.name, src=def.def), rg)>;";
  }
  ret += "function initVals(){";
  for (def <- rg.defs) {
    str name = def.name;
    if (/answerExpression(id(name), AType t, _) := f) {
      ret += "<mangleId(id(name, src=def.def), rg)> = document.getElementById(\"<mangleId(id(name, src=def.def), rg)>\");";
      ret += "<mangleId(id(name, src=def.def), rg)>." + access2js(t) + "=" + defaultValues(t) + ";";
    }
    else if (/answer(id(name), AType t) := f) {
      ret += "<mangleId(id(name, src=def.def), rg)> = document.getElementById(\"<mangleId(id(name, src=def.def), rg)>\");";
      ret += "<mangleId(id(name, src=def.def), rg)>." + access2js(t) + "=" + defaultValues(t) + ";";
    }
  }
  ret += "}";
  return ret;
}

str expr2js(AExpr e, TEnv tenv, RefGraph rg) {
  str ret = "(";
  switch (e) {
    case ref(AId id): {
      ret += "<mangleId(id, rg)>." + access2js(typeOf(e, tenv, rg.useDef));
    }
    case boolLiteral(bool boolVal): {
      ret += "<boolVal>";
    }
    case intLiteral(int intVal): {
      ret += "<intVal>";
    }
    case strLiteral(str strVal): {
      ret += strVal;
    }
    case singleExpr(AExpr expr): {
      ret += expr2js(expr, tenv, rg);
    }
    case not(AExpr expr): {
      ret += "!<expr2js(expr, tenv, rg)>";
    }
    case mul(AExpr exprLeft, AExpr exprRight): {
      ret += expr2js(exprLeft, tenv, rg) + "*" + expr2js(exprRight, tenv, rg);
    }
    case div(AExpr exprLeft, AExpr exprRight): {
      ret += expr2js(exprLeft, tenv, rg) + "/" + expr2js(exprRight, tenv, rg);
    }
    case sub(AExpr exprLeft, AExpr exprRight): {
      ret += expr2js(exprLeft, tenv, rg) + "-" + expr2js(exprRight, tenv, rg);
    }
    case add(AExpr exprLeft, AExpr exprRight): {
      ret += expr2js(exprLeft, tenv, rg) + "+" + expr2js(exprRight, tenv, rg);
    }
    case lt(AExpr exprLeft, AExpr exprRight): {
      ret += expr2js(exprLeft, tenv, rg) + "\<" + expr2js(exprRight, tenv, rg);
    }
    case le(AExpr exprLeft, AExpr exprRight): {
      ret += expr2js(exprLeft, tenv, rg) + "\<=" + expr2js(exprRight, tenv, rg);
    }
    case gt(AExpr exprLeft, AExpr exprRight): {
      ret += expr2js(exprLeft, tenv, rg) + "\>" + expr2js(exprRight, tenv, rg);
    }
    case ge(AExpr exprLeft, AExpr exprRight): {
      ret += expr2js(exprLeft, tenv, rg) + "\>=" + expr2js(exprRight, tenv, rg);
    }
    case eqq(AExpr exprLeft, AExpr exprRight): {
      ret += expr2js(exprLeft, tenv, rg) + "==" + expr2js(exprRight, tenv, rg);
    }
    case neq(AExpr exprLeft, AExpr exprRight): {
      ret += expr2js(exprLeft, tenv, rg) + "!=" + expr2js(exprRight, tenv, rg);
    }
    case and(AExpr exprLeft, AExpr exprRight): {
      ret += expr2js(exprLeft, tenv, rg) + "&&" + expr2js(exprRight, tenv, rg);
    }
    case or(AExpr exprLeft, AExpr exprRight): {
      ret += expr2js(exprLeft, tenv, rg) + "||" + expr2js(exprRight, tenv, rg);
    }
  }
  ret += ")";
  return ret;
}

str refreshVisibility(TEnv tenv, RefGraph rg) {
  str ret = "";
  for (m <- condMap) {
    ret += "if(<expr2js(m.expr, tenv, rg)>){";
      ret += "document.getElementById(\"ifStatement<m.conditionalId>\").style.display = \"block\";";
      ret += "let tmp = document.getElementById(\"elseStatement<m.conditionalId>\");";
      ret += "if(tmp){";
        ret += "tmp.style.display = \"none\";";
      ret += "}";
    ret += "}";
    ret += "else{";
      ret += "document.getElementById(\"ifStatement<m.conditionalId>\").style.display = \"none\";";
      ret += "let tmp = document.getElementById(\"elseStatement<m.conditionalId>\");";
      ret += "if(tmp){";
        ret += "tmp.style.display = \"block\";";
      ret += "}";
    ret += "}";
  }
  return ret;
}

str refreshVars(AForm f, TEnv tenv, RefGraph rg) {
  str ret = "";
  for (def <- rg.defs) {
    str name = def.name;
    if (/answerExpression(id(name), AType t, AExpr expr) := f) {
      ret += "if(elem.id != \"<mangleId(id(name, src=def.def), rg)>\"){";
      ret += "<mangleId(id(name, src=def.def), rg)>.<access2js(t)>=<expr2js(expr, tenv, rg)>";
      ret += "}";
    }
  }
  return ret;
}

str refresh(AForm f, TEnv tenv, RefGraph rg) {
  str ret = "function refresh(elem){";
  ret += "if(elem !== undefined){";
  ret += refreshVars(f, tenv, rg);
  ret += "}";
  ret += refreshVisibility(tenv, rg);
  ret += "}";
  return ret;
}

str form2js(AForm f, RefGraph rg) {
  str ret = "";
  TEnv tenv = collect(f);
  ret += initVals(f, rg);
  ret += refresh(f, tenv, rg);
  ret += "initVals();";
  ret += "refresh();";
  return ret;
}
