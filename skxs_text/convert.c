#include "datatypes.h"
#include "lexer.h"
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>

/* lemon functions */
extern void *TxtParseAlloc(void *(*mallocproc)(size_t));
extern void TxtParse(void *, int, struct Token, struct ExtraState *);
extern void TxtParseFree(void *, void (*freeProc)(void *));

int
main(void)
{
	char buf[1159] = { 0 };
	char *buf_put = &buf[0];

	{ /* 1. load a file */
		size_t i;
		int c;
		FILE *test = fopen("test_files/ballots_house_intro.txt", "rb");
		for (i = 0; i < sizeof(buf); i++)
		{
			c = fgetc(test);
			if (c == EOF)
			{
				break;
			}
			*buf_put = (char) c;
			buf_put++;
		}
		/* Ensure nul-terminated string */
		buf[sizeof(buf) - 1] = '\0';
		fclose(test);
	}

	fprintf(ERR_BUF, "File loaded\n");

	{ /* 2. Tokenize and parse it in one go, thanks to Lemon */
		struct Token token;
		const char *buf_view = &buf[0];
		long bytes_to_go = (long) sizeof(buf);
		void *parser = NULL;
		struct ExtraState s = { 0 };

		fprintf(ERR_BUF, "%lu bytes remain\n", bytes_to_go);

		/* prepare the parser engine */
		parser = TxtParseAlloc(malloc);
		assert(parser);

		/* perform lexing and parsing in one go */
		do
		{
			token = get_next_token(&buf_view, &bytes_to_go);
			token.origin = &buf[0];
			if (token.which > TK_invalid)
			{
				TxtParse(parser, token.which, token, &s);
				if (s.has_error)
				{
					break;
				}
			}
		} while (token.which > TK_invalid);

		/* end parsing */
		TxtParse(parser, 0, token, &s);
		TxtParseFree(parser, free);

		fprintf(ERR_BUF,
				"\n%lu bytes remain, last token %d\n",
				bytes_to_go,
				token.which);
	}

	return 0;
}
