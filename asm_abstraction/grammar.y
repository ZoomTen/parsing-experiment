/* settings */
%token_type {struct Token}
%token_prefix TK_

/* make output predictable */
%token
    HEX_NUMBER COLON STRING OPEN_BRACKET
    CLOSE_BRACKET IDENTIFIER SUB OPEN_PAREN
    CLOSE_PAREN ASM ASM_LITERAL.

/* storing additional information about my parser state */
%extra_argument { struct InternalState *s }

/* rules */
start ::= program.
{
    printf("Got\n");
}

program ::= HEX_NUMBER COLON HEX_NUMBER STRING OPEN_BRACKET SUB IDENTIFIER IDENTIFIER OPEN_PAREN CLOSE_PAREN OPEN_BRACKET ASM OPEN_BRACKET ASM_LITERAL CLOSE_BRACKET CLOSE_BRACKET CLOSE_BRACKET.
{
    printf("Got\n");
}

%syntax_error
{
    printf("Error :(\n");
}

%include
{
    #include <stdio.h>
    struct Token {
        int kind;
        int position;
        int length;
        char * word;
    };
    struct InternalState {
        char dummy;
    };
}