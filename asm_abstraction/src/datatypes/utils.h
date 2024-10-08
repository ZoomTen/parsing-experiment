#ifndef DATATYPES_UTILS_H
#define DATATYPES_UTILS_H

#include "shared.h"

/* The following are links to functions defined in ./utils.nim */
extern Node *make_node_raw(void);
extern void assign_node_ref_generic(Node **a, Node *b);
extern int number_from_hex_token(Token a);
extern void add_node_generic(Seq *a, Node *b);
extern void assign_cstr_generic(const char **const a, const char *const b);

#endif /* DATATYPES_UTILS_H */
