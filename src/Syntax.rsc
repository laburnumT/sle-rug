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
  = Id
  | Bool
  | Int
  | Str
  | "(" Expr ")"
  | Expr "-" Expr
  | Expr "+" Expr
  | Expr "*" Expr
  | Expr "/" Expr
  ;

syntax If_statement
  = "if" "(" Expr ")" "{" Question* questions "}"
  ;
  
syntax Type
  = "boolean"
  | "integer"
  | "string";

lexical Str 
  = "\"" (![\"]|"\\\"")* "\""
  ;

lexical Int 
  = 
  ;

lexical Bool
  = "true"
  | "false"
  ;