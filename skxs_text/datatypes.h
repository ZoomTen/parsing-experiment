#ifndef DATATYPES_H
#define DATATYPES_H
#include <stddef.h>

struct Token
{
	const char *origin; /* The entire original source text from whence this token came. */
	const char *where; /* The exact starting point of the token. */
	size_t length;
	int which;
};

struct ExtraState
{
    _Bool has_error;
};

#define TK_invalid 0

#define ERR_BUF stderr
#define OUT_BUF stdout

#endif // DATATYPES_H
