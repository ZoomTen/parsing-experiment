/* settings */
%name CharMapParse
%token_type { const char* }
%token_prefix CM_TK_

%token
	NEWCHARMAP
	CHARMAPNUM
	CHARMAP
	COMMA
	HEX_NUM
	STRING
	EOL
.

%extra_argument {struct CharMapExtraState *s}

%include
{
	#include "../process/charmap.h"
	#include <string.h>
	#include <stdlib.h>

	void add_mapping(const char *string, const char *hexnum, struct CharMapExtraState *s)
	{
		/* Assuming `string` is `"..."` */
		int codepoint = utf8_to_codepoint(&string[1]);

		/* Assuming hexnum is `$..` */
		unsigned char hex_num = (unsigned char) strtol(&hexnum[1], NULL, 16);

		codepoint_mappings[(codepoint * 2)] = (int) s->current_index;
		codepoint_mappings[(codepoint * 2) + 1] = (int) hex_num;
	}
}

start ::= charmap.

charmap ::= charmap_definition charmap_list.
charmap ::= charmap charmap_definition charmap_list.

charmap_definition ::= NEWCHARMAP CHARMAPNUM(A).
{
	/* Assuming there are only 9 charmaps */
	char a[sizeof("charmapX")] = { 0 };
	memcpy(a, A, sizeof("charmapX") - 1);
	s->current_index = a[sizeof("charmap") - 1] - '0';
}

charmap_list ::= CHARMAP STRING(A) COMMA HEX_NUM(B).
{
	add_mapping(A, B, s);
}

charmap_list ::= charmap_list CHARMAP STRING(A) COMMA HEX_NUM(B).
{
	add_mapping(A, B, s);
}

%syntax_error
{
    printf("Syntax error on %s\n", TOKEN);
    s->has_error = 1;
}
