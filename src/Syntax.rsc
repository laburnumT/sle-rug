module Syntax

extend lang::std::Id;
extend lang::std::Layout;

/*
 * Concrete syntax of QL
 */
start syntax Form
  = "form" Id name "{" Question* questions "}"
  ;

syntax Prompt
  = Str
  ;

// TODO: question, computed question, block, if-then-else, if-then
syntax Question
  = Prompt question Answer answerVar
  | IfStatement ifStatement
  ;

syntax Answer
  = Id answerVar ":" Type type
  | Id answerVar ":" Type type "=" Expr expr
  ;

// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)
syntax Expr
  = Id \ Keywords
  | Bool
  | Int
  | Str
  | "(" Expr ")"
  > right "!" Expr
  > left (
      Expr lhs "*" Expr rhs
    | Expr lhs "/" Expr rhs
  )
  > left (
      Expr lhs "-" Expr rhs
    | Expr lhs "+" Expr rhs
  )
  > left (
      Expr lhs "\<"  Expr rhs
    | Expr lhs "\<=" Expr rhs
    | Expr lhs "\>"  Expr rhs
    | Expr lhs "\>=" Expr rhs
  )
  > left (
      Expr lhs "==" Expr rhs
    | Expr lhs "!=" Expr rhs
  )
  > left Expr lhs "&&" Expr rhs
  > left Expr lhs "||" Expr rhs
  ;

syntax IfStatement
  = "if" "(" Expr expr ")" "{" Question* questions "}"
  | "if" "(" Expr expr ")" "{" Question* questions "}" ElseStatement elseStatement
  ;

syntax ElseStatement
  = "else" "{" Question* questions "}"
  | "else" IfStatement ifStatement
  ;

syntax Type
  = "boolean"
  | "integer"
  | "string"
  ;

lexical Str
  = "\"" (![\"]|"\\\"")* "\""
  ;

lexical Int
  = "-"? [0-9]+
  ;

lexical Bool
  = "true"
  | "false"
  ;

keyword Keywords
  = "form"
  | "true"
  | "false"
  | "if"
  | "else"
  | "boolean"
  | "integer"
  | "string"
  ;
