%token TOKEN_PRINT
%token TOKEN_FUNCTION
%token TOKEN_FOR
%token TOKEN_IF
%token TOKEN_ELSE
%token TOKEN_RETURN
%token TOKEN_LEFT_BRACE
%token TOKEN_RIGHT_BRACE
%token TOKEN_LEFT_PAREN
%token TOKEN_RIGHT_PAREN
%token TOKEN_LEFT_BRACKET
%token TOKEN_RIGHT_BRACKET
%token TOKEN_STRING
%token TOKEN_INTEGER
%token TOKEN_CHAR
%token TOKEN_VOID
%token TOKEN_BOOLEAN
%token TOKEN_ARRAY
%token TOKEN_GE
%token TOKEN_LE
%token TOKEN_EQ
%token TOKEN_NE
%token TOKEN_LT
%token TOKEN_GT
%token TOKEN_AND
%token TOKEN_OR
%token TOKEN_NOT
%token TOKEN_INCREMENT
%token TOKEN_DECREMENT
%token TOKEN_ADD
%token TOKEN_SUBTRACT
%token TOKEN_MULTIPLY
%token TOKEN_DIVIDE
%token TOKEN_MODULUS
%token TOKEN_EXPONENTIATE
%token TOKEN_ASSIGN
%token TOKEN_COMMA
%token TOKEN_COLON
%token TOKEN_SEMICOLON
%token TOKEN_TRUE
%token TOKEN_FALSE
%token TOKEN_CHAR_LITERAL
%token TOKEN_INTEGER_LITERAL
%token TOKEN_STRING_LITERAL
%token TOKEN_IDENTIFIER
%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "decl.h"
#include "stmt.h"
#include "expr.h"
#include "type.h"
#include "param_list.h"
#include "symbol.h"
/*
Clunky: Manually declare the interface to the scanner generated by flex. 
*/
extern char *yytext;
extern int yylex();
extern int yyerror( char *str );

/*
Clunky: Keep the final result of the parse in a global variable,
so that it can be retrieved by main().
*/
struct decl *parser_result = 0;
%}

%union {
	struct decl *decl;
	struct expr *expr;
	struct stmt *stmt;
	struct type *type;
	struct param_list *param_list;
	char *name;
	int integer;
};


%type <decl> program decl_list decl;
%type <expr> expr compare_expr add_expr mul_expr expon_expr neg_expr incr_expr opt_expr expr_list not_empty_expr_list primary_expr;
%type <stmt> stmt open_stmt closed_stmt stmt_list not_empty_stmt_list;
%type <type> type;
%type <param_list> param_list not_empty_param_list param;
%type <name> identifier string_literal;
%type <integer> integer_literal char_literal;

%%

program: decl_list {
	$$ = $1;
	parser_result = $1;
	return 0;
}
	;

decl_list: decl decl_list {
	$1 -> next = $2;
	$$ = $1;
}
	| decl {
	$$ = $1;
}
	;

decl: identifier colon type assign expr semicolon {
	$$ = decl_create($1,$3,$5,0,0);
}
	| identifier colon type semicolon {
	$$ = decl_create($1,$3,0,0,0);
}
	| identifier colon type assign left_brace stmt_list right_brace {
	$$ = decl_create($1,$3,0,$6,0);
}
	;

stmt: open_stmt {
	$$ = $1;
}
	| closed_stmt {
	$$ = $1;
}
	;

closed_stmt: decl {
	$$ = stmt_create(STMT_DECL,$1,0,0,0,0,0);
}
	| expr semicolon {
	$$ = stmt_create(STMT_EXPR,0,0,$1,0,0,0);
}
	| return opt_expr semicolon {
	$$ = stmt_create(STMT_RETURN,0,0,$2,0,0,0);
}
	| print expr_list semicolon {
	$$ = stmt_create(STMT_PRINT,0,0,$2,0,0,0);
}
	| for left_paren opt_expr semicolon opt_expr semicolon opt_expr right_paren closed_stmt {
	$$ = stmt_create(STMT_FOR,0,$3,$5,$7,$9,0);
}
	| if left_paren expr right_paren closed_stmt else closed_stmt {
	$$ = stmt_create(STMT_IF_ELSE,0,0,$3,0,$5,$7);
}
	| left_brace stmt_list right_brace {
	$$ = stmt_create(STMT_BLOCK,0,0,0,0,0,$2);
}
	;

open_stmt: if left_paren expr right_paren stmt {
	$$ = stmt_create(STMT_IF_ELSE,0,0,$3,0,$5,0);
}
	| if left_paren expr right_paren closed_stmt else open_stmt {
	$$ = stmt_create(STMT_IF_ELSE,0,0,$3,0,$5,$7);
}
	| for left_paren opt_expr semicolon opt_expr semicolon opt_expr right_paren open_stmt {
	$$ = stmt_create(STMT_FOR,0,$3,$5,$7,$9,0);
}
	;

stmt_list: not_empty_stmt_list {
	$$ = $1;
}
	| /* nothing */ {
}
	;

not_empty_stmt_list: stmt not_empty_stmt_list {
	$1 -> next = $2;
	$$ = $1;
}
	| stmt {
	$$ = $1;
}
	;

expr: expr and compare_expr {
	$$ = expr_create(EXPR_ADD,$1,$3);
}
	| expr or compare_expr {
	$$ = expr_create(EXPR_OR,$1,$3);
}
	| compare_expr {
	$$ = $1;
}
	;

compare_expr: add_expr ne add_expr {
	$$ = expr_create(EXPR_NE,$1,$3);
}
	| add_expr gt add_expr {
	$$ = expr_create(EXPR_GT,$1,$3);
}
	| add_expr ge add_expr {
	$$ = expr_create(EXPR_GE,$1,$3);
}
	| add_expr lt add_expr {
	$$ = expr_create(EXPR_LT,$1,$3);
}
	| add_expr le add_expr {
	$$ = expr_create(EXPR_LE,$1,$3);
}
	| add_expr eq add_expr {
	$$ = expr_create(EXPR_EQ,$1,$3);
}
	| add_expr {
	$$ = $1;
}
	;

add_expr: add_expr add mul_expr {
	$$ = expr_create(EXPR_ADD,$1,$3);
}
	| add_expr subtract mul_expr {
	$$ = expr_create(EXPR_SUB,$1,$3);
}
	| mul_expr {
	$$ = $1;
}
	;

mul_expr: mul_expr multiply expon_expr {
	$$ = expr_create(EXPR_MUL,$1,$3);
}
	| mul_expr divide expon_expr {
	$$ = expr_create(EXPR_DIV,$1,$3);
}
	| mul_expr modulus expon_expr {
	$$ = expr_create(EXPR_MOD,$1,$3);
}
	| expon_expr {
	$$ = $1;
}
	;

expon_expr: neg_expr exponentiate expon_expr {
	$$ = expr_create(EXPR_EXPON,$1,$3);
}
	| neg_expr {
	$$ = $1;
}
	;

neg_expr: subtract incr_expr {
	$$ = expr_create(EXPR_NEG,$2,0);
}
	| not incr_expr {
	$$ = expr_create(EXPR_NOT,$2,0);
}
	| incr_expr {
	$$ = $1;
}
	;

incr_expr: primary_expr increment {
	$$ = expr_create(EXPR_INCR,$1,0);
}
	| primary_expr decrement {
	$$ = expr_create(EXPR_DECR,$1,0);
}
	| primary_expr {
	$$ = $1;
}
	;

opt_expr: expr {
	$$ = $1;
}
	| /* nothing */ {
}
	;

expr_list: not_empty_expr_list {
	$$ = $1;
}
	| /* nothing */ {
}
	;

not_empty_expr_list: expr comma not_empty_expr_list {
	$$ = expr_create(EXPR_LIST,$1,$3);
}
	| expr {
	$$ = expr_create(EXPR_LIST,$1,0);
}
	;

primary_expr: identifier {
	$$ = expr_create_name($1);
}
	| identifier left_paren expr_list right_paren {
	struct expr *id = expr_create_name($1);
	$$ = expr_create(EXPR_FUNC,id,$3);
}
	| integer_literal {
	$$ = expr_create_integer_literal($1);
}
	| string_literal {
	$$ = expr_create_string_literal($1);
}
	| char_literal {
	$$ = expr_create_character_literal($1);
}
	| true {
	$$ = expr_create_boolean_literal(1);
}
	| false {
	$$ = expr_create_boolean_literal(0);
}
	| left_paren expr right_paren {
	$$ = $2;
}
	| left_brace not_empty_expr_list right_brace {
	$$ = $2;
}
	;

type: integer {
	$$ = type_create(TYPE_INTEGER,0,0);
}
	| void {
	$$ = type_create(TYPE_VOID,0,0);
}
	| string {
	$$ = type_create(TYPE_STRING,0,0);
}
	| char {
	$$ = type_create(TYPE_CHARACTER,0,0);
}
	| boolean {
	$$ = type_create(TYPE_BOOLEAN,0,0);
}
	| array left_bracket opt_expr right_bracket type {
	$$ = type_create(TYPE_ARRAY,0,$5);
}
	| function type left_paren param_list right_paren {
	$$ = type_create(TYPE_FUNCTION,$4,$2);
}
	;

param_list: not_empty_param_list {
	$$ = $1;
}
	| /* nothing */ {
}
	;

not_empty_param_list: param {
	$$ = $1;
}
	| param comma not_empty_param_list {
	$1 -> next = $3;
	$$ = $1;
}
	;

param:	type colon identifier {
	$$ = param_list_create($3,$1,0);
}
	;

/* Redefinitions of terminals */
print: TOKEN_PRINT;
function: TOKEN_FUNCTION;
for: TOKEN_FOR;
if: TOKEN_IF;
else: TOKEN_ELSE;
return: TOKEN_RETURN;
left_brace: TOKEN_LEFT_BRACE;
right_brace: TOKEN_RIGHT_BRACE;
left_paren: TOKEN_LEFT_PAREN;
right_paren: TOKEN_RIGHT_PAREN;
left_bracket: TOKEN_LEFT_BRACKET;
right_bracket: TOKEN_RIGHT_BRACKET;
string: TOKEN_STRING;
integer: TOKEN_INTEGER;
char: TOKEN_CHAR;
void: TOKEN_VOID;
boolean: TOKEN_BOOLEAN;
array: TOKEN_ARRAY;
ge: TOKEN_GE;
le: TOKEN_LE;
eq: TOKEN_EQ;
ne: TOKEN_NE;
lt: TOKEN_LT;
gt: TOKEN_GT;
and: TOKEN_AND;
or: TOKEN_OR;
not: TOKEN_NOT;
increment: TOKEN_INCREMENT;
decrement: TOKEN_DECREMENT;
add: TOKEN_ADD;
subtract: TOKEN_SUBTRACT;
multiply: TOKEN_MULTIPLY;
divide: TOKEN_DIVIDE;
modulus: TOKEN_MODULUS;
exponentiate: TOKEN_EXPONENTIATE;
assign: TOKEN_ASSIGN;
comma: TOKEN_COMMA;
colon: TOKEN_COLON;
semicolon: TOKEN_SEMICOLON;
true: TOKEN_TRUE;
false: TOKEN_FALSE;
char_literal: TOKEN_CHAR_LITERAL {
	$$ = yytext[0];
};
integer_literal: TOKEN_INTEGER_LITERAL {
	$$ = atoi(yytext);
};
string_literal: TOKEN_STRING_LITERAL {
	char *str = malloc(sizeof(char) * 256);
	strcpy(str,yytext);
	$$ = str;
};
identifier: TOKEN_IDENTIFIER {
	char *id = malloc(sizeof(char) * 256);
	strcpy(id,yytext);
	$$ = id;
};

%%

int yyerror(char *str) {
	printf("yytext: %s\n",yytext);
	printf("parse error: %s\n",str);
	return 1;
}
