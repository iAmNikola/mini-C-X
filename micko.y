%{
  #include <stdio.h>
  #include <string.h>
  #include <stdlib.h>
  #include "defs.h"
  #include "symtab.h"
  #include "codegen.h"

  int yyparse(void);
  int yylex(void);
  int yyerror(char *s);
  void warning(char *s);

  extern int yylineno;
  int out_lin = 0;
  char char_buffer[CHAR_BUFFER_LENGTH];
  int error_count = 0;
  int warning_count = 0;
  int var_num = 0;
  int fun_idx = -1;
  int fcall_idx = -1;
  int lab_num = -1;
  FILE *output;

  // union
  char *union_name;
  int union_counter = 0;
  int union_var_num = 0;
  bool union_active;
  bool cast_active;
  unsigned cast_to_type;
  char *variable_name = "";
  char *left_var_name;
  char *right_var_name;
%}

%union {
  int i;
  char *s;
}

%token <i> _TYPE
%token _IF
%token _ELSE
%token _RETURN
%token <s> _ID
%token <s> _INT_NUMBER
%token <s> _UINT_NUMBER
%token _LPAREN
%token _RPAREN
%token _LBRACKET
%token _RBRACKET
%token _ASSIGN
%token _SEMICOLON
%token <i> _AROP
%token <i> _RELOP
%token _UNION
%token _DOT

%type <i> num_exp exp literal cast_exp
%type <i> function_call argument rel_exp if_part

%nonassoc ONLY_IF
%nonassoc _ELSE

%right CAST

%%

program
  : union_list function_list
      {  
        if(lookup_symbol("main", FUN) == NO_INDEX)
          err("undefined reference to 'main'");
      }
  ;

function_list
  : function
  | function_list function
  ;

function
  : _TYPE _ID
      {
        fun_idx = lookup_symbol($2, FUN);
        if(fun_idx == NO_INDEX)
          fun_idx = insert_symbol($2, FUN, $1, NO_ATR, NO_ATR);
        else 
          err("redefinition of function '%s'", $2);

        code("\n%s:", $2);
        code("\n\t\tPUSH\t%%14");
        code("\n\t\tMOV \t%%15,%%14");
      }
    _LPAREN parameter _RPAREN body
      {
        clear_symbols(fun_idx + 1);
        var_num = 0;
        
        code("\n@%s_exit:", $2);
        code("\n\t\tMOV \t%%14,%%15");
        code("\n\t\tPOP \t%%14");
        code("\n\t\tRET");
      }
  | _UNION _ID _ID
    {
        fun_idx = lookup_symbol($3, FUN);
        if (lookup_symbol($2, UNION_K) != NO_INDEX) {
          if(fun_idx == NO_INDEX)
            fun_idx = insert_symbol_union($3, FUN, UNION, NO_ATR, NO_ATR, $2);
          else 
            err("redefinition of function '%s'", $3);
        }
        else
          err("No union definition with name %s", $2);
        code("\n%s:", $3);
        code("\n\t\tPUSH\t%%14");
        code("\n\t\tMOV \t%%15,%%14");
      }
    _LPAREN parameter _RPAREN body
      {
        clear_symbols(fun_idx + 1);
        var_num = 0;
        code("\n@%s_exit:", $3);
        code("\n\t\tMOV \t%%14,%%15");
        code("\n\t\tPOP \t%%14");
        code("\n\t\tRET");
      }
  ;

parameter
  : /* empty */
      { set_atr1(fun_idx, 0); }

  | _TYPE _ID
      {
        insert_symbol($2, PAR, $1, 1, NO_ATR);
        set_atr1(fun_idx, 1);
        set_atr2(fun_idx, $1);
      }
  | _UNION _ID _ID
      {
        insert_symbol_union($3, PAR, UNION, 1, NO_ATR, $2);
        set_atr1(fun_idx, 1);
        set_atr2(fun_idx, UNION);
      }
  ;

body
  : _LBRACKET variable_list
      {
        if(var_num)
          code("\n\t\tSUBS\t%%15,$%d,%%15", 4*var_num);
        code("\n@%s_body:", get_name(fun_idx));
      }
    statement_list _RBRACKET
  ;

variable_list
  : /* empty */
  | variable_list variable
  ;

variable
  : _TYPE _ID _SEMICOLON
      {
        if (union_active) {
          if (lookup_symbol_union($2, union_name) == NO_INDEX)
            insert_symbol_union($2, UNION_VAR, $1, ++union_var_num, union_counter, union_name);
          else
            err("redefinition of %s in %s union", $2, union_name);
        }
        else if(lookup_symbol($2, VAR|PAR) == NO_INDEX)
           insert_symbol($2, VAR, $1, ++var_num, NO_ATR);
        else 
           err("redefinition of '%s'", $2);
      }
  | _UNION _ID _ID _SEMICOLON
    {
      if (union_active)
        err("Union cannot contain a union.");
      else {
        if (lookup_symbol($2, UNION_K) != NO_INDEX) {
          if (lookup_symbol($3, VAR) == NO_INDEX)
            insert_symbol_union($3, VAR, UNION, ++var_num, NO_ATR, $2);
          else
            err("Variable with name %s is already defined", $3);
        }
        else
          err("No union definition with name %s", $2);
      }
    }
  ;

statement_list
  : /* empty */
  | statement_list statement
  ;

statement
  : compound_statement
  | assignment_statement
  | if_statement
  | return_statement
  ;

compound_statement
  : _LBRACKET statement_list _RBRACKET
  ;

assignment_statement
  : _ID _ASSIGN num_exp _SEMICOLON
      {
        int idx = lookup_symbol($1, VAR|PAR);
        if(idx == NO_INDEX)
          err("invalid lvalue '%s' in assignment", $1);
        else
          if(cast_active) {
            if(get_type(idx) != cast_to_type)
              err("incompatible types in assignment. Value is casted to wrong type");
            cast_active = 0;
            cast_to_type = NO_TYPE;
          }
          else
            if(get_type(idx) != get_type($3))
              err("incompatible types in assignment");
        gen_mov($3, idx);
      }
  | _ID _DOT _ID _ASSIGN num_exp _SEMICOLON
    {
      int union_idx = lookup_symbol($1, VAR|PAR);
      if(union_idx == NO_INDEX)
        err("invalid lvalue '%s' in assignment", $1);
      else {
        // check if $3 _ID is variable in union definition and is valid type
        int union_var_idx = lookup_symbol_union_kind($3, UNION_VAR, get_union_name(union_idx));
        if(union_var_idx != NO_INDEX)
          if(cast_active) {
            if(get_type(union_var_idx) != cast_to_type)
              err("incompatible types in assignment. Value is casted to wrong type");
            cast_active = 0;
            cast_to_type = NO_TYPE;
          }
          else {
            if(get_type(union_var_idx) == get_type($5)) {
              // Sets union variable's active variable to the var_num in union definition
              set_active_variable(union_idx, get_atr1(union_var_idx));
            }
            else
              err("incompatible types in assignment");
          }
        else
          err("Union '%s' doesn't have variable with name %s", get_union_name(union_idx) ,$3);
      }
      if(get_kind($5) == UNION_VAR)
        gen_mov(lookup_symbol(variable_name, VAR|PAR), union_idx);
      else
        gen_mov($5, union_idx);
    }
  ;

num_exp
  : cast_exp

  | num_exp { left_var_name = variable_name; } _AROP cast_exp
      {
        right_var_name = variable_name;
        if(get_type($1) != get_type($4))
          err("invalid operands: arithmetic operation");
        int t1 = get_type($1);
        code("\n\t\t%s\t", ar_instructions[$3 + (t1 - 1) * AROP_NUMBER]);
        if(get_kind($1) == UNION_VAR)
          gen_sym_name(lookup_symbol(left_var_name, VAR|PAR));
        else
          gen_sym_name($1);
        code(",");
        if(get_kind($4) == UNION_VAR)
          gen_sym_name(lookup_symbol(right_var_name, VAR|PAR));
        else
          gen_sym_name($4);
        code(",");
        free_if_reg($4);
        free_if_reg($1);
        $$ = take_reg();
        gen_sym_name($$);
        set_type($$, t1);
      }
  ;

exp
  : literal
  | _ID
      {
        $$ = lookup_symbol($1, VAR|PAR);
        if($$ == NO_INDEX)
          err("'%s' undeclared", $1);
      }

  | function_call
      {
        $$ = take_reg();
        gen_mov(FUN_REG, $$);
      }
  
  | _LPAREN num_exp _RPAREN
      { $$ = $2; }

  | _ID _DOT _ID
    {
      int union_idx = lookup_symbol($1, VAR|PAR);
      if(union_idx == NO_INDEX)
        err("variable '%s' undeclared", $1);
      else {
        variable_name = $1;
        $$ = lookup_symbol_union_kind($3, UNION_VAR, get_union_name(union_idx));
        if($$ == NO_INDEX)
          err("Union '%s' doesn't have variable with name %s", get_union_name(union_idx) ,$3);
        else {
            if (get_kind(union_idx) == VAR) {
              int union_var_idx = get_atr1($$);
              if(union_var_idx != get_active_variable(union_idx))
                err("Union member '%s' is not active.", $3);
            }
          }
      }
    }
  ;

cast_exp
  : exp
  
  | _LPAREN _TYPE _RPAREN exp %prec CAST
    {
      cast_active = 1;
      cast_to_type = $2;
      $$ = $4;
    }
  ;

literal
  : _INT_NUMBER
      { $$ = insert_literal($1, INT); }

  | _UINT_NUMBER
      { $$ = insert_literal($1, UINT); }
  ;

function_call
  : _ID 
      {
        fcall_idx = lookup_symbol($1, FUN);
        if(fcall_idx == NO_INDEX)
          err("'%s' is not a function", $1);
      }
    _LPAREN argument _RPAREN
      {
        if(get_atr1(fcall_idx) != $4)
          err("wrong number of arguments");
        code("\n\t\t\tCALL\t%s", get_name(fcall_idx));
        if($4 > 0)
          code("\n\t\t\tADDS\t%%15,$%d,%%15", $4 * 4);
        set_type(FUN_REG, get_type(fcall_idx));
        $$ = FUN_REG;
      }
  ;

argument
  : /* empty */
    { $$ = 0; }

  | num_exp
    { 
      if(cast_active) {
        if(get_type(fcall_idx) != cast_to_type)
          err("incompatible type for argument. Value is casted to wrong type");
        cast_active = 0;
        cast_to_type = NO_TYPE;
      }
      else
        if(get_atr2(fcall_idx) != get_type($1))
          err("incompatible type for argument");
      free_if_reg($1);
      code("\n\t\t\tPUSH\t");
      gen_sym_name($1);
      $$ = 1;
    }
  ;

if_statement
  : if_part %prec ONLY_IF
      { code("\n@exit%d:", $1); }

  | if_part _ELSE statement
      { code("\n@exit%d:", $1); }
  ;

if_part
  : _IF _LPAREN
      {
        $<i>$ = ++lab_num;
        code("\n@if%d:", lab_num);
      }
    rel_exp
      {
        code("\n\t\t%s\t@false%d", opp_jumps[$4], $<i>3);
        code("\n@true%d:", $<i>3);
      }
    _RPAREN statement
      {
        code("\n\t\tJMP \t@exit%d", $<i>3);
        code("\n@false%d:", $<i>3);
        $$ = $<i>3;
      }
  ;

rel_exp
  : num_exp _RELOP num_exp
      {
        if(get_type($1) != get_type($3))
          err("invalid operands: relational operator");
        $$ = $2 + ((get_type($1) - 1) * RELOP_NUMBER);
        gen_cmp($1, $3);
      }
  ;

return_statement
  : _RETURN num_exp _SEMICOLON
      {
        if(cast_active) {
            if(get_type(fun_idx) != cast_to_type)
              err("incompatible types in return. Value is casted to wrong type");
            cast_active = 0;
            cast_to_type = NO_TYPE;
          }
        else
          if(get_type(fun_idx) != get_type($2))
            err("incompatible types in return");
        if(get_kind($2) == UNION_VAR) {
          gen_mov(lookup_symbol(variable_name, VAR|PAR), FUN_REG);
        }
        else
          if(get_type($2) == UNION) {
            if(strcmp(get_union_name(fun_idx), get_union_name($2)) == 0)
              gen_mov($2, FUN_REG);
            else
              err("incompatible union types in return.");
          }
          else
            gen_mov($2, FUN_REG);
        code("\n\t\tJMP \t@%s_exit", get_name(fun_idx));        
      }
  ;

union_list
  : /* empty */
  | union_list union_definition
  ;

union_definition
  : _UNION _ID 
    { 
      union_active = 1;
      union_name = $2;
      if (lookup_symbol(union_name, UNION_K) == NO_INDEX) {
        insert_symbol(union_name, UNION_K, NO_TYPE, ++union_counter, NO_ATR);
      }
      else {
        err("Union with name %s already exists", $2);
      }
    }
    _LBRACKET variable_list
    {
      if (union_var_num) {
        union_active = 0;
        union_var_num = 0;
      }
      else {
        err("Union %s doesn't have attributes.", $2);
      }
    }
    _RBRACKET _SEMICOLON
  ;

%%

int yyerror(char *s) {
  fprintf(stderr, "\nline %d: ERROR: %s", yylineno, s);
  error_count++;
  return 0;
}

void warning(char *s) {
  fprintf(stderr, "\nline %d: WARNING: %s", yylineno, s);
  warning_count++;
}

int main() {
  int synerr;
  init_symtab();
  output = fopen("output.asm", "w+");

  synerr = yyparse();

  clear_symtab();
  fclose(output);
  
  if(warning_count)
    printf("\n%d warning(s).\n", warning_count);

  if(error_count) {
    remove("output.asm");
    printf("\n%d error(s).\n", error_count);
  }

  if(synerr)
    return -1;  //syntax error
  else if(error_count)
    return error_count & 127; //semantic errors
  else if(warning_count)
    return (warning_count & 127) + 127; //warnings
  else
    return 0; //OK
}

