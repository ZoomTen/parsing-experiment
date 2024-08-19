/* settings */
%token_type {Token}
%token_prefix TK_

/* must match order in ../shared.nim */
%token
    HEX_NUMBER
    COLON
    STRING
    OPEN_BRACKET
    CLOSE_BRACKET
    IDENTIFIER
    SUB
    OPEN_PAREN
    CLOSE_PAREN
    ASM
    ASM_LITERAL
    REGISTER
.

/* storing additional information about my parser state */
%extra_argument { InternalState *s }

/* rules */
start ::= program.
{
    printf("Got start\n");
}

program ::= HEX_NUMBER COLON HEX_NUMBER STRING OPEN_BRACKET SUB IDENTIFIER IDENTIFIER OPEN_PAREN CLOSE_PAREN OPEN_BRACKET ASM OPEN_BRACKET ASM_LITERAL CLOSE_BRACKET CLOSE_BRACKET CLOSE_BRACKET.
{
    printf("Got program\n");
}

%syntax_error
{
    printf("Error :(\n");
}

%include
{
    #include <stdio.h>
    #include "../datatypes/shared.h"
}
