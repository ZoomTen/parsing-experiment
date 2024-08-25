#include "charmap.h"
#include "../datatypes.h"
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

int codepoint_mappings[65536 * 2];

/* FLEX functions */
extern int char_map_yylex_init(void **);
extern int char_map_yylex_destroy(void *);
extern int char_map_yyset_in(FILE *, void *);
extern int char_map_yyset_out(FILE *, void *);
extern int char_map_yylex(void *);
extern const char *char_map_yyget_text(void *);

/* lemon functions */
extern void *CharMapParseAlloc(void *(*mallocproc)(size_t));
extern void CharMapParse(void *, int, const char *,
						 struct CharMapExtraState *);
extern void CharMapParseFree(void *, void (*freeProc)(void *));

int
process_charmap(const char *filename)
{
	/* initialize mappings */
	for (size_t i = 0;
		 i < (sizeof(codepoint_mappings) / sizeof(codepoint_mappings[0]));
		 i++)
	{
		codepoint_mappings[i] = -1;
	}

	if (!filename)
	{
		fprintf(ERR_BUF, "No filename provided!\n");
		return 1;
	}

	void *scanner;
	if (char_map_yylex_init(&scanner))
	{
		fprintf(ERR_BUF, "Can't initialize scanner!\n");
		return 1;
	}

	FILE *f_in = fopen(filename, "rb");
	if (!f_in)
	{
		fprintf(ERR_BUF, "Can't open file %s: %m\n", filename);
		char_map_yylex_destroy(scanner);
		return 1;
	}

	char_map_yyset_in(f_in, scanner);
	struct CharMapExtraState state = { 0 };
	void *parser = CharMapParseAlloc(malloc);
	int token = char_map_yylex(scanner);
	while (token)
	{
		CharMapParse(parser, token, char_map_yyget_text(scanner), &state);
		if (state.has_error)
		{
			break;
		}
		token = char_map_yylex(scanner);
	}
	fclose(f_in);
	CharMapParse(parser, 0, 0, &state);

	char_map_yylex_destroy(scanner);
	CharMapParseFree(parser, free);

	return 0;
}

int
utf8_to_codepoint(const char *utf8_tri)
{
	int codepoint = (int) utf8_tri[2] & 63;
	codepoint |= ((int) (utf8_tri[1] & 63)) << 6;
	codepoint |= ((int) (utf8_tri[0] & 15)) << 12;
	return codepoint;
}
