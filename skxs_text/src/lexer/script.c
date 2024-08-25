#include <string.h>
#include "../parser/script.h"
#include "../datatypes.h"
#include "script.h"
#include <stdio.h>
#include <stdlib.h>

/*
 * A hand-made tokenizer, lexer, whatever it's called.
 */
struct ScriptToken
get_next_token(
	/*
	 * A view onto some buffer that the caller determines. As this is going to
	 * be changed (slided) directly, the caller shouldn't use the pointer to
	 * the buffer itself, but rather a pointer's copy.
	 */
	const char **view,
	/*
	 * Usually this would be a `buffer_size` that is set and updated by the
	 * caller. Here, I flip the script on its head and have the caller
	 * determine beforehand how big the buffer is. That will be updated
	 * directly in here, so the caller can just hands-off and let this thing
	 * spin.
	 */
	long *bytes_to_go)
{
	/* Set the defaults */
	struct ScriptToken result = { .which = SCR_TK_invalid,
								  .where = NULL,
								  .length = 0 };

	/*
	 * Sanity check, this can't continue when it runs out of bytes to process.
	 */
	if (*bytes_to_go < 1)
	{
		fprintf(ERR_BUF, "ran out of bytes!\n");
		return result;
	}

	/* Comments last until the end of the line, I ignore them here */
	if (**view == '#')
	{
	starting_at_a_comment: /*  Come from switch(c) case '#' */
		while (*bytes_to_go > 0)
		{
			if ((**view == '\r') || (**view == '\n'))
			{ /*
			   * bail out and let the whitespace autoskipper take it from here
			   */
				break;
			}
			else
			{
				*view += 1;
				*bytes_to_go -= 1;
			}
		}
	}

	/* Skip white space */
	while (*bytes_to_go > 0)
	{
		if ((**view == '\r') || (**view == '\n') || (**view == '\t') ||
			(**view == ' '))
		{
			*view += 1;
			*bytes_to_go -= 1;
		}
		else
		{
			break; /* do */
		}
	}

	/* Check again, just in case. */
	if (*bytes_to_go < 1)
	{
		/* fprintf(ERR_BUF, "no token to be found after whitespace...\n"); */
		return result;
	}

	/* The fun begins */
	result.where = *view;
	switch (**view)
	{
		case '@': /* SCR_TK_ORG '@org' */
		{
			/*
			 * Peek into the next few characters to
			 * determine if `@org` is matched
			 */
			char check_org[4] = { 0 };
			if (4 > *bytes_to_go)
			{
				fprintf(ERR_BUF, "expected 3 more characters after '@'\n");
				return result;
			}

			check_org[0] = (*view)[1];
			check_org[1] = (*view)[2];
			check_org[2] = (*view)[3];

			if (strcmp(check_org, "org"))
			{ /* Case sensitive check for now */
				fprintf(ERR_BUF, "expected 'org' after '@'\n");
				return result;
			}

			result.which = SCR_TK_ORG;
			result.length = 4;
			*bytes_to_go -= result.length;
			*view += result.length;
			return result;
		}
		case '$': /* SCR_TK_HEX_NUM '$abcdef' */
		{
			/* Peek as far as possible to get the entire number */
			size_t ii;
			size_t final_size = 1;

			if (2 > *bytes_to_go)
			{
				fprintf(ERR_BUF, "expected character after '$'\n");
				return result;
			}

			for (ii = 1; (long) ii < *bytes_to_go; ii++)
			{ /* Case-insensitive check */
				if (((*view)[ii] >= '0' && (*view)[ii] <= '9') ||
					((*view)[ii] >= 'a' && (*view)[ii] <= 'f') ||
					((*view)[ii] >= 'A' && (*view)[ii] <= 'f'))
				{
					final_size++;
				}
				else
				{
					break; /* for */
				}
			}

			if (final_size < 2)
			{ /* Detected string consists only of a '$' */
				fprintf(ERR_BUF, "invalid hex number\n");
				return result;
			}

			result.which = SCR_TK_HEXNUM;
			result.length = final_size;
			*bytes_to_go -= result.length;
			*view += result.length;
			return result;
		}
		case '(': /* SCR_TK_LEFT_PAREN '(' */
		{
			result.which = SCR_TK_LEFT_PAREN;
			result.length = 1;
			*bytes_to_go -= result.length;
			*view += result.length;
			return result;
		}
		case ')': /* SCR_TK_RIGHT_PAREN '(' */
		{
			result.which = SCR_TK_RIGHT_PAREN;
			result.length = 1;
			*bytes_to_go -= result.length;
			*view += result.length;
			return result;
		}
		case 'A' ... 'Z':
		case 'a' ... 'z':
		case '_': /* SCR_TK_IDENTIFIER and others */
		{
			/* SCR_TK_TEXT */
			/* SCR_TK_LINE */
			/* SCR_TK_DONE */
			/* SCR_TK_INIT */
			size_t ii;
			size_t final_size = 0;
			char *id_buffer;

			/* Fetch as far as possible first */
			for (ii = 0; (long) ii < *bytes_to_go; ii++)
			{
				if (((*view)[ii] >= '0' && (*view)[ii] <= '9') ||
					((*view)[ii] >= 'A' && (*view)[ii] <= 'Z') ||
					((*view)[ii] >= 'a' && (*view)[ii] <= 'z') ||
					((*view)[ii] == '_'))
				{
					final_size++;
				}
				else
				{
					break; /* for */
				}
			}

			/* Prepare reserved keyword check */
			id_buffer = calloc(sizeof(char), final_size + 1);
			memcpy(&id_buffer[0], *view, final_size);

			result.length = final_size;
			*bytes_to_go -= result.length;
			*view += result.length;

			/* Detect reserved keywords */
			if (!strcmp(id_buffer, "init"))
			{
				free(id_buffer);
				result.which = SCR_TK_INIT;
				return result;
			}
			else if (!strcmp(id_buffer, "text"))
			{
				free(id_buffer);
				result.which = SCR_TK_TEXT;
				return result;
			}
			else if (!strcmp(id_buffer, "line"))
			{
				free(id_buffer);
				result.which = SCR_TK_LINE;
				return result;
			}
			else if (!strcmp(id_buffer, "para"))
			{
				free(id_buffer);
				result.which = SCR_TK_PARA;
				return result;
			}
			else if (!strcmp(id_buffer, "cont"))
			{
				free(id_buffer);
				result.which = SCR_TK_CONT;
				return result;
			}
			else if (!strcmp(id_buffer, "done"))
			{
				free(id_buffer);
				result.which = SCR_TK_DONE;
				return result;
			}
			else
			{
				free(id_buffer);
				result.which = SCR_TK_IDENTIFIER;
				return result;
			}
		}
		case ':': /* SCR_TK_COLON */
		{
			result.which = SCR_TK_COLON;
			result.length = 1;
			*bytes_to_go -= result.length;
			*view += result.length;
			return result;
		}
		case ',': /* SCR_TK_COMMA */
		{
			result.which = SCR_TK_COMMA;
			result.length = 1;
			*bytes_to_go -= result.length;
			*view += result.length;
			return result;
		}
		case ';': /* SCR_TK_SEMICOLON */
		{
			result.which = SCR_TK_SEMICOLON;
			result.length = 1;
			*bytes_to_go -= result.length;
			*view += result.length;
			return result;
		}
		case '"': /* SCR_TK_QUOTED_STRING */
		{
			size_t ii;
			size_t final_size = 0;
			_Bool encountered_end_quote = 0;

			/* Nothing after a " ? */
			if (2 > *bytes_to_go)
			{
				fprintf(ERR_BUF, "expected character after '\"'\n");
				return result;
			}

			/* Fetch as far as possible */
			for (ii = 1; (long) ii < *bytes_to_go; ii++)
			{
				if ((*view)[ii] == '"')
				{ /* no escapes yet, sadly.. */
					encountered_end_quote = 1;
					break; /* for */
				}
				else
				{
					final_size++;
				}
			}

			if (!encountered_end_quote)
			{
				fprintf(ERR_BUF, "quote not terminated yet\n");
				return result;
			}

			/* Cover the ending quote too */
			final_size = ii + 1;

			result.which = SCR_TK_QUOTED_STRING;
			result.length = final_size;
			*bytes_to_go -= result.length;
			*view += result.length;
			return result;
		}
		case '#': /* line comment */
		{
			goto starting_at_a_comment;
		}
		default:
		{
			break; /* case */
		}
	}
	return result;
}
