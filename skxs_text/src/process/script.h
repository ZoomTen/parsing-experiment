#ifndef PROCESS_SCRIPT_H
#define PROCESS_SCRIPT_H
#include <stddef.h>

int
process_script(char *filename);

struct ExtraState
{
    _Bool has_error;
    int last_saved_charset;
};

#endif /* PROCESS_SCRIPT_H */
