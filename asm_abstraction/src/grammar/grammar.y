/* settings */
%token_type {Token}
%token_prefix TK_

/* must match order in ../shared.nim */
%token
    HEX_NUMBER
    COLON
    STRING
    OPEN_BRACKET
    CLOSE_BRACKET
    IDENTIFIER
    SUB
    OPEN_PAREN
    CLOSE_PAREN
    ASM
    ASM_LITERAL
    REGISTER
    DATA
    SEMICOLON
    EQUALS
.

/* storing additional information about my parser state */
%extra_argument { InternalState *s }

/* rules */

/*
 * The first rule of the grammar, all it does is assign the
 * generated tree to to our internal state.
 */
start ::= program(A).
{
    s->tree = A;
}

%type program { ProgramNode* }
program(A) ::= section(B).
{
    A = (ProgramNode *) (void *) make_node(N_PROGRAM);
    add_node_generic(&A->program_items, (Node *) B);
}

program(A) ::= program(A) section(B).
{
	add_node_generic(&A->program_items, (Node*) B);
}

%type section { SectionBlockNode* }
section(A) ::= rom_address(B) STRING(C) OPEN_BRACKET subs_datas(D) CLOSE_BRACKET.
{
    A = (SectionBlockNode *) make_node(N_SECTION_BLOCK);
    assign_node_ref_generic((Node **) &A->at_address, (Node*) B);
    A->section_name = C.word;
    A->section_content = D;
}

/*
 * Can't just do empty subs_datas because of a parser conflict,
 * and can't do subs_datas optional because the value isn't guaranteed
 * to be nil if it isn't there.
 */
section(A) ::= rom_address(B) STRING(C) OPEN_BRACKET CLOSE_BRACKET.
{
    A = (SectionBlockNode *) make_node(N_SECTION_BLOCK);
    assign_node_ref_generic((Node **) &A->at_address, (Node*) B);
    A->section_name = C.word;
}

%type rom_address { RomAddressNode* }
rom_address(A) ::= HEX_NUMBER(B) COLON HEX_NUMBER(C).
{
    A = (RomAddressNode *) make_node(N_ROM_ADDRESS);
    A->bank = number_from_hex_token(B);
    A->address = number_from_hex_token(C);
    A->flattened_address = (
        A->bank == 0
            ? A->address
            : ((A->bank * 0x4000) + (A->address - 0x4000))
    );
}

%type subs_datas { SubAndDataListNode* }
subs_datas(A) ::= sub(B).
{
    A = (SubAndDataListNode *) make_node(N_SUB_AND_DATA_LIST);
    add_node_generic(&A->subs_datas, (Node*) B);
}

subs_datas(A) ::= subs_datas(A) sub(B).
{
    add_node_generic(&A->subs_datas, (Node*) B);
}

subs_datas(A) ::= data(B).
{
    A = (SubAndDataListNode *) make_node(N_SUB_AND_DATA_LIST);
    add_node_generic(&A->subs_datas, (Node*) B);
}

subs_datas(A) ::= subs_datas(A) data(B).
{
    add_node_generic(&A->subs_datas, (Node*) B);
}

%type sub { SubBlockNode* }
sub(A) ::= SUB IDENTIFIER(B) OPEN_PAREN CLOSE_PAREN OPEN_BRACKET CLOSE_BRACKET.
{
    A = (SubBlockNode *) make_node(N_SUB_BLOCK);
    A->sub_name = B.word;
}

sub(A) ::= SUB IDENTIFIER(B) OPEN_PAREN CLOSE_PAREN OPEN_BRACKET sub_content(C) CLOSE_BRACKET.
{
    A = (SubBlockNode *) make_node(N_SUB_BLOCK);
    A->sub_name = B.word;
    A->sub_content = (Seq *) C;
}

%type data { DataBlockNode* }
data(A) ::= DATA IDENTIFIER(B) OPEN_BRACKET CLOSE_BRACKET.
{
    A = (DataBlockNode *) make_node(N_DATA_BLOCK);
    A->data_name = B.word;
}

%type sub_content { SubContentNode* }
sub_content(A) ::= asm(B).
{
    A = (SubContentNode *) make_node(N_SUB_CONTENT);
    add_node_generic(&A->sub_items, (Node*) B);
}

sub_content(A) ::= assignment(B).
{
    A = (SubContentNode *) make_node(N_SUB_CONTENT);
    add_node_generic(&A->sub_items, (Node*) B);
}

sub_content(A) ::= sub_content(A) asm(B).
{
    add_node_generic(&A->sub_items, (Node*) B);
}

sub_content(A) ::= sub_content(A) assignment(B).
{
    add_node_generic(&A->sub_items, (Node*) B);
}

%type asm { AsmLiteralNode* }
asm(A) ::= ASM OPEN_BRACKET CLOSE_BRACKET.
{
    A = (AsmLiteralNode *) make_node(N_ASM_LITERAL);
}

asm(A) ::= ASM OPEN_BRACKET ASM_LITERAL(B) CLOSE_BRACKET.
{
    A = (AsmLiteralNode *) make_node(N_ASM_LITERAL);
    A->asm_content = B.word;
}

%type assignment { AssignmentNode* }
assignment(A) ::= REGISTER(B) EQUALS REGISTER(C) SEMICOLON.
{
    A = (AssignmentNode *) make_node(N_ASSIGNMENT);

    RegisterNode *lhs = (RegisterNode *) make_node(N_REGISTER);
    lhs->reg_name = B.word;

    RegisterNode *rhs = (RegisterNode *) make_node(N_REGISTER);
    rhs->reg_name = C.word;

    A->assign_target = (GenericNode *) lhs;
    A->assign_value = (GenericNode *) rhs;
}

%syntax_error
{
    printf("Error :(\n");
}

%include
{
    #include <stdio.h>
    #include "../datatypes/shared.h"
    #include "../datatypes/utils.h"
    #include <string.h>

	/*
	 * Nim does not allow changing the discriminant in an object variant;
	 * it results in a FieldDefect in release mode.
	*
	 * Here, we insist that we "know what we're doing" and change it
	 * right here through C code.
	 */
	Node *make_node(NodeKind kind)
	{
		Node *r = make_node_raw();
		r->_ = kind;
		return r;
	}
}
