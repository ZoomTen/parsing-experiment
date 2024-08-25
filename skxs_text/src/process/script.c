#include "../lexer/script.h"
#include "../datatypes.h"
#include "script.h"
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>

/* lemon functions */
extern void *ScriptParseAlloc(void *(*mallocproc)(size_t));
extern void ScriptParse(void *, int, struct ScriptToken, struct ExtraState *);
extern void ScriptParseFree(void *, void (*freeProc)(void *));

int
process_script(char *filename)
{
	char *buffer;
	size_t size_of_file;

	{ /* 1. load a file */
		if (!filename)
		{
			fprintf(ERR_BUF, "No filename provided!\n");
			return 1;
		}

		FILE *test = fopen(filename, "rb");
		if (!test)
		{
			fprintf(ERR_BUF, "Can't open file %s: %m\n", filename);
			return 1;
		}

		/* Determine the size of file */
		fseek(test, 0L, SEEK_END);
		size_of_file = ftell(test);
		rewind(test);

		/* Load file into the buffer */
		buffer = malloc(size_of_file + 1);
		assert(buffer);

		char *buf_import_view = &buffer[0];
		for (size_t i = 0; i < size_of_file; i++)
		{
			*buf_import_view = (char) fgetc(test);
			buf_import_view++;
		}

		fclose(test);

		fprintf(ERR_BUF, "File loaded\n");
	}

	{ /* 2. Tokenize and parse it in one go, thanks to Lemon */
		struct ScriptToken token;
		const char *buf_view = &buffer[0];
		long bytes_to_go = (long) size_of_file;
		void *parser = NULL;
		struct ExtraState s = { 0 };

		fprintf(ERR_BUF, "%lu bytes remain\n", bytes_to_go);

		/* prepare the parser engine */
		parser = ScriptParseAlloc(malloc);
		assert(parser);

		/* perform lexing and parsing in one go */
		do
		{
			token = get_next_token(&buf_view, &bytes_to_go);
			token.origin = &buffer[0];
			if (token.which > SCR_TK_invalid)
			{
				ScriptParse(parser, token.which, token, &s);
				if (s.has_error)
				{
					break;
				}
			}
		} while (token.which > SCR_TK_invalid);

		/* end parsing */
		ScriptParse(parser, 0, token, &s);
		ScriptParseFree(parser, free);

		fprintf(ERR_BUF,
				"\n%lu bytes remain, last token %d\n",
				bytes_to_go,
				token.which);
	}

	free(buffer);
	return 0;
}
