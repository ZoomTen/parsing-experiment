%option prefix="char_map_yy"
%option reentrant
%option noyywrap

%{ /* includes */
	#include "../datatypes.h"
	#include "../parser/charmap.h"
%}

/* rules */

define_kw    "NEWCHARMAP"
charmap_no   charmap[0-9]+
charmap_def  charmap
comma        ,
hex_num      \$[0-9a-fA-F]+
string       \".+\"


%% /* actions. Starting brace MUST be in the same line as defn */

{define_kw} {
	return CM_TK_NEWCHARMAP;
}

{charmap_no} {
	return CM_TK_CHARMAPNUM;
}

{charmap_def} {
	return CM_TK_CHARMAP;
}

{comma} {
	return CM_TK_COMMA;
}

{hex_num} {
	return CM_TK_HEX_NUM;
}

{string} {
	return CM_TK_STRING;
}

.|\n|;.+ {
	int len = yyget_leng( yyscanner );
	yyget_text( yyscanner )[len - 1] = '\0';
}

%%
