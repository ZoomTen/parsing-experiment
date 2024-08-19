#ifndef DATATYPES_SHARED_H
#define DATATYPES_SHARED_H

typedef struct {
	char dummy;
} InternalState;

typedef struct {
	int kind;
	int position;
	int length;
	char *word;
} Token;

#endif // DATATYPES_SHARED_H
