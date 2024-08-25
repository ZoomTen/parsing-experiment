#ifndef LEXER_SCRIPT_H
#define LEXER_SCRIPT_H
#include <stddef.h>

struct ScriptToken
{
	const char *origin; /* The entire original source text from whence this token came. */
	const char *where; /* The exact starting point of the token. */
	size_t length;
	int which;
};

#define SCR_TK_invalid 0

struct ScriptToken get_next_token(const char **view, long *bytes_to_go);

#endif // LEXER_SCRIPT_H
