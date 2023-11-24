module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form
  = "form" Id name "{" Question* questions "}";

// TODO: question, computed question, block, if-then-else, if-then
syntax Question
  = Str Answer
  | If_statement if_statement
  ;

syntax Answer
  = Id answer_var ":" Type type
  | Id answer_var ":" Type type "=" Expr expr
  ;

// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)
syntax Expr
  = Id \ "true" \ "false"
  | Bool
  | Int
  | Str
  | bracket "(" Expr ")"
  > left (
      Expr "*" Expr
    | left Expr "/" Expr
  )
  > left (
      Expr "-" Expr
    | left Expr "+" Expr
  )
  > left (
      Expr "\<" Expr
    | Expr "\<=" Expr
    | Expr "\>" Expr
    | Expr "\>=" Expr
  )
  > left (
      Expr "==" Expr
    | Expr "!=" Expr
  )
  > left Expr "&&" Expr
  > left Expr "||" Expr
  ;

syntax If_statement
  = "if" "(" Expr ")" "{" Question* questions "}"
  | "if" "(" Expr ")" "{" Question* questions "}" Else_statement else_statement
  ;

syntax Else_statement
  = "else" "{" Question* questions "}"
  | "else" "(" Expr ")" "{" Question* questions "}"
  ;

syntax Type
  = "boolean"
  | "integer"
  | "string";

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
