/* settings */
%name ScriptParse
%token_type {struct ScriptToken}
%token_prefix SCR_TK_

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

%include
{ /* Standard C code to be injected in the generated file goes here. */
    #include "../lexer/script.h"
    #include "../process/script.h"
    #include "../process/charmap.h"
    #include "../datatypes.h"
    #include <stdio.h>
    #include <string.h>
    #include <stdlib.h>

    /* Spits out a copy of what the detected token was. */
    char *copy_token_string(struct ScriptToken t)
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
    void report_syntax_error(struct ScriptToken t)
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

/* rules */
start ::= script.

script ::= org COLON body. /* A single define */
script ::= script org COLON body. /* Multiple defines */

/* @org $xx, $yyyy: */
org ::= ORG HEXNUM(A) COMMA HEXNUM(B).
{
    char *bank_num = copy_token_string(A);
    char *addr = copy_token_string(B);
    {
        fprintf(OUT_BUF, "\ntext_%s_%s::\n", bank_num + 1, addr + 1);
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
        fprintf(OUT_BUF, "\n%s:: ; %s:%s\n", id, bank_num + 1, addr + 1);
    }
    free(id);
    free(addr);
    free(bank_num);
}

body ::= stmt SEMICOLON. /* A single statement */
body ::= body stmt SEMICOLON. /* Multiple statements */

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
{
why:
    s->last_saved_charset = -1;
    char *txt = copy_token_string(A);
    {
        size_t l = strlen(txt);
        size_t i;

        fprintf(OUT_BUF, "\ttext \"");
        for (i = 1; i < l-1; i+=3)
        {
            int codepoint = utf8_to_codepoint(&txt[i]);
            int charset = codepoint_mappings[codepoint * 2];
            if (charset != s->last_saved_charset)
            {
                fprintf(
                    OUT_BUF,
                    "%c%c%c\", %d\n\ttext \"",
                    txt[i] & 0xff,
                    txt[i + 1] & 0xff,
                    txt[i + 2] & 0xff,
                    charset
                );
                s->last_saved_charset = charset;
            }
            else
            {
                fprintf(
                    OUT_BUF,
                    "%c%c%c",
                    txt[i] & 0xff,
                    txt[i + 1] & 0xff,
                    txt[i + 2] & 0xff
                );
            }
        }
        fprintf(OUT_BUF, "\"\n");
    }
    free(txt);
}

/* line "Hello" */
stmt ::= LINE QUOTED_STRING(A).
{
    (void)(A);
    fprintf(OUT_BUF, "\tline\n");
    goto why;
}

/* para "Hello" */
stmt ::= PARA QUOTED_STRING(A).
{
    (void)(A);
    fprintf(OUT_BUF, "\tpara\n");
    goto why;
}

/* cont "Hello" */
stmt ::= CONT QUOTED_STRING(A).
{
	(void)(A);
	fprintf(OUT_BUF, "\tcont\n");
    goto why;
}

/* done */
stmt ::= DONE.
{
    fprintf(OUT_BUF, "\tdone\n");
}
