/* Prologue (directives).   -*- C++ -*- */

/* Disable Flex features we don't need, to avoid warnings. */
%option nodefault noinput nounput noyywrap

%option reentrant

%{
#include <limits.h> /* INT_MIN */
#include <stdlib.h> /* strtol */

#include "parse.h"
%}

%x SC_STRING

%%
%{
  int nesting = 0;
  char *str = NULL;
  int size = 0;
  int capacity = 0;
#define STR_APPEND()                                    \
  do {                                                  \
    if (capacity < size + 1)                            \
      {                                                 \
        do                                              \
          capacity = capacity ? 2 * capacity : 128;     \
        while (capacity < size + 1);                    \
        str = realloc (str, capacity);                  \
      }                                                 \
    strncpy (str + size, yytext, yyleng);               \
    size += yyleng;                                     \
  } while (0)
%}

 // Rules.

"+"      return TOK_PLUS;
"-"      return TOK_MINUS;
"*"      return TOK_STAR;
"/"      return TOK_SLASH;

"("      nesting += 1; BEGIN SC_STRING;

 /* Scan an integer.  */
[0-9]+   {
  errno = 0;
  long n = strtol (yytext, NULL, 10);
  if (! (INT_MIN <= n && n <= INT_MAX && errno != ERANGE))
    yyerror (yyscanner, res, "integer is out of range");
  yylval->TOK_NUM = (int) n;
  return TOK_NUM;
}

 /* Ignore white spaces. */
[ \t]+   continue;

"\n"     return TOK_EOL;

.        yyerror (yyscanner, res, "syntax error, invalid character");

<SC_STRING>
{
  "("*   nesting += yyleng; STR_APPEND ();
  ")"    {
    if (!--nesting)
      {
        BEGIN INITIAL;
        yylval->TOK_STR = str;
        return TOK_STR;
      }
    else
      STR_APPEND ();
  }
  [^()]+  STR_APPEND ();
}

<<EOF>>  return TOK_EOF;
%%
/* Epilogue (C code). */