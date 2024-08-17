#ifndef DATATYPES_H
#define DATATYPES_H
#include <stddef.h>

struct Token
{
	const char *origin;
	const char *where;
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
