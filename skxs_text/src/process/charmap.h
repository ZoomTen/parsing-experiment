#ifndef PROCESS_CHARMAP_H
#define PROCESS_CHARMAP_H

int
process_charmap(const char *filename);

/* set, then index */
extern int codepoint_mappings[65536 * 2];

struct CharMapExtraState
{
    _Bool has_error;
    unsigned char current_index;
};

extern int
utf8_to_codepoint(const char *utf8_tri);

#endif /* PROCESS_CHARMAP_H */
