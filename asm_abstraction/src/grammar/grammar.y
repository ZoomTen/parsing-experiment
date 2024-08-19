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

program ::= section.
program ::= program section.
program ::= program_parts.

section ::= rom_address STRING OPEN_BRACKET program_parts CLOSE_BRACKET.
rom_address ::= HEX_NUMBER COLON HEX_NUMBER.

program_parts ::= sub.
program_parts ::= program_parts sub.

sub ::= SUB IDENTIFIER OPEN_PAREN CLOSE_PAREN OPEN_BRACKET sub_body CLOSE_BRACKET.

sub_body ::= asm.
sub_body ::= sub_body asm.

asm ::= ASM OPEN_BRACKET ASM_LITERAL CLOSE_BRACKET.

%syntax_error
{
    printf("Error :(\n");
}

%include
{
    #include <stdio.h>
    #include "../datatypes/shared.h"
}
