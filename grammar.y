/* settings */
%token_type {struct Token}
%token_prefix TK_

/* make output predictable */
%token
    ORG HEXNUM COLON COMMA
    LEFT_PAREN IDENTIFIER RIGHT_PAREN
    SEMICOLON INIT TEXT QUOTED_STRING
    LINE PARA DONE.

/* storing additional information about my parser state */
%extra_argument { struct ExtraState *s }

%syntax_error
{
    /* `TOKEN` is a special word, Lemon's docs are kinda lacking here :( */
    report_syntax_error(TOKEN);
    s->has_error = 1;
}

/* rules */
start ::= program.

program ::= org COLON body. /* A single define */
program ::= org COLON body program. /* Multiple defines */

/* @org $xx, $yyyy: */
org ::= ORG HEXNUM(A) COMMA HEXNUM(B).
{
    char *bank_num = copy_token_string(A);
    char *addr = copy_token_string(B);
    {
        fprintf(OUT_BUF, "text_%s_%s::\n", bank_num + 1, addr + 1);
    }
    free(addr);
    free(bank_num);
}

/* @org $xx, $yyyy: */
org ::= ORG HEXNUM(A) COMMA HEXNUM(B)
        LEFT_PAREN IDENTIFIER(C) RIGHT_PAREN.
{
    char *bank_num = copy_token_string(A);
    char *addr = copy_token_string(B);
    char *id = copy_token_string(C);
    {
        fprintf(OUT_BUF, "%s:: ; %s:%s\n", id, bank_num + 1, addr + 1);
    }
    free(id);
    free(addr);
    free(bank_num);
}

body ::= stmt SEMICOLON. /* A single statement */
body ::= stmt SEMICOLON body. /* Multiple statements */

arg ::= IDENTIFIER.
arg ::= HEXNUM.

/* init SOMETHING, SOMETHING_ELSE */
stmt ::= INIT arg(A) COMMA arg(B).
{
    char *arg1 = copy_token_string(A);
    char *arg2 = copy_token_string(B);
    {
        fprintf(OUT_BUF, "\ttext_init %s, %s\n", arg1, arg2);
    }
    free(arg2);
    free(arg1);
}

/* text "Hello" */
stmt ::= TEXT QUOTED_STRING(A).
{ /* TODO */
    char *txt = copy_token_string(A);
    {
        size_t l = strlen(txt);
        size_t i;
        for (i = 1; i < l-1; i++)
        {
            fprintf(OUT_BUF, "\t0x%02x\n", txt[i] & 0xff);
        }
        fprintf(OUT_BUF, "\t%s\n", txt);
    }
    free(txt);
}

/* line "Hello" */
stmt ::= LINE QUOTED_STRING.
{ /* TODO */ }

/* para "Hello" */
stmt ::= PARA QUOTED_STRING.
{ /* TODO */ }

/* cont "Hello" */
stmt ::= CONT QUOTED_STRING.
{ /* TODO */ }

/* done */
stmt ::= DONE.
{
    fprintf(OUT_BUF, "\tdone\n");
}

%include
{ /* Standard C code to be injected in the generated file goes here. */
    #include "datatypes.h"
    #include <stdio.h>
    #include <string.h>
    #include <stdlib.h>

    /* Spits out a copy of what the detected token was. */
    char *copy_token_string(struct Token t)
    {
        if (!t.where)
        {
            return NULL;
        }
        char *i = calloc(sizeof(char), t.length + 1);
        memcpy(&i[0], &t.where[0], t.length);
        return i;
    }

    /* Not quite as good yet... */
    void report_syntax_error(struct Token t)
    {
        char *n = NULL;
        if (t.where != NULL)
        {
            size_t len = t.length;
            n = malloc(len + 1);
            n[len] = '\0';
            memcpy(&n[0], t.where, len);
        }
        fprintf(ERR_BUF, "Error in syntax near %d: %s\n", t.where?(int)(t.where-t.origin):-1, n?n:"");
        if (n)
        {
            free(n);
        }
    }
}
