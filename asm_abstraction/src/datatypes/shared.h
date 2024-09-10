#ifndef DATATYPES_SHARED_H
#define DATATYPES_SHARED_H

typedef struct
{
	int kind;
	int position;
	int length;
	char *word;
} Token;

/*
** This strongly assumes Nim v2.x's sequence implementations
** so it's just the bare minimum that's needed for it
*/
typedef struct
{
	int len;
	void *items;
} Seq;

typedef long long NodeKindId;

/*
** Nim's implementation of object variants are to put every member in a large
** struct, and each members visibility is determined by the kind of variant.
**
** Postgres on the other hand for its AST has like two million different structs
** all with the same starting members, and you need to cast between the
** different ones depending on the kind.
**
** When compiled to C, it's basically a union. So pretty much the exact same.
*/

/*
 * The most basic kind of node. `_` is a stand-in for `kind`. For alignment
 * reasons, _ is an int64.
 */
typedef struct
{
	NodeKindId _;
} Node;

/* Must match enum order in ./shared.nim */
typedef enum
{
	N_GENERIC = 0,
	N_IDENTIFIER,
	N_ROM_ADDRESS,
	N_SECTION_BLOCK,
	N_SUB_BLOCK,
	N_REGISTER,
	N_PROGRAM,
	N_SUB_AND_DATA_LIST,
	N_SUB_CONTENT,
	N_DATA_BLOCK,
	N_DATA_CONTENT,
	N_ASM_LITERAL,
	N_ASSIGNMENT,
} NodeKind;

typedef Node GenericNode;

typedef struct
{
	NodeKindId _;
	const char *ident;
} IdentifierNode;

typedef struct
{
	NodeKindId _;
	int bank;
	int address;
	int flattened_address;
} RomAddressNode;

typedef struct
{
	NodeKindId _;
	const char *sub_name;
	Seq *sub_content;
} SubBlockNode;

typedef struct
{
	NodeKindId _;
	const char *reg_name;
} RegisterNode;

typedef struct
{
	NodeKindId _;
	Seq program_items;
} ProgramNode;

typedef struct
{
	NodeKindId _;
	Seq subs_datas;
} SubAndDataListNode;

typedef struct
{
	NodeKindId _;
	RomAddressNode *at_address;
	const char *section_name;
	SubAndDataListNode *section_content;
} SectionBlockNode;

typedef struct
{
	NodeKindId _;
	Seq sub_items;
} SubContentNode;

typedef struct
{
	NodeKindId _;
	Seq data_items;
} DataContentNode;

typedef struct
{
	NodeKindId _;
	const char *data_name;
	DataContentNode *data_content;
} DataBlockNode;

typedef struct
{
	NodeKindId _;
	const char *asm_content;
} AsmLiteralNode;

typedef struct
{
	NodeKindId _;
	GenericNode *assign_target;
	GenericNode *assign_value;
} AssignmentNode;

typedef struct
{
	ProgramNode *tree;
} InternalState;

#endif // DATATYPES_SHARED_H
