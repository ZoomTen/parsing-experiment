#include "datatypes.h"
#include "process/charmap.h"
#include "process/script.h"
#include <stdio.h>

int
main(int argc, char **argv)
{
	if (argc < 3)
	{
		fprintf(ERR_BUF, "%s charmap.asm script.txt > script.asm\n", argv[0]);
		return 0;
	}

	process_charmap(argv[1]);
	process_script(argv[2]);
	return 0;
}
