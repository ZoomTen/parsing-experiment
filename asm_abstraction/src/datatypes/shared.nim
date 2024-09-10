# jank
from os import splitPath
const sharedHeader = currentSourcePath().splitPath.head & "/shared.h"

type
  # Must match enum order in ../grammar/grammar.y
  TokenKind* {.size: sizeof(cint).} = enum
    Invalid = 0
    HexNumber
    Colon
    String
    OpenBracket
    CloseBracket
    IdentifierToken
    Sub
    OpenParen
    CloseParen
    Asm
    AsmLiteralToken
    RegisterToken
    Data
    Semicolon
    Equals

  # State of the lexer that can be accessed from Lemon
  # Must match corresponding struct in ./shared.h
  InternalState* {.byref, importc, header: sharedHeader.} = object
    tree*: NodeRef

  # Incidental token
  # Must match corresponding struct in ./shared.h
  Token* {.bycopy, importc, header: sharedHeader.} = object
    kind*: TokenKind
    position*: cint
    length*: cint
    word*: cstring

  # Must match enum order in ./shared.h
  NodeKind* {.size: sizeof(int64).} = enum
    Generic = 0
    IdentifierNode
    RomAddress
    SectionBlock
    SubBlock
    RegisterNode
    Program
    SubAndDataList
    SubContent
    DataBlock
    DataContent
    AsmLiteralNode
    Assignment

  # each case-arm's structure on the Nim side MUST match the structure of
  # the different structs on the C side. `struct Seq` must be used to represent
  # Nim sequences.
  Node* = object
    case kind*: NodeKind
    of Generic:
      discard
    of IdentifierNode:
      ident*: cstring
    of RomAddress:
      bank*: cint
      address*: cint
      flattened_address*: cint
    of SectionBlock:
      at_address*: NodeRef # RomAddress
      section_name*: cstring
      section_content*: NodeRef # SubAndDataList
    of SubBlock:
      sub_name*: cstring
      sub_content*: NodeRef # SubContent
    of RegisterNode:
      reg_name*: cstring
    of Program:
      program_items*: seq[NodeRef]
    of SubAndDataList:
      subs_datas*: seq[NodeRef]
    of SubContent:
      sub_items*: seq[NodeRef]
    of DataBlock:
      data_name*: cstring
      data_content*: NodeRef # DataContent
    of DataContent:
      data_items*: seq[NodeRef]
    of AsmLiteralNode:
      asm_content*: cstring
    of Assignment:
      assign_target*: NodeRef # Register / Identifier
      assign_value*: NodeRef # Register / Identifier / Expr

  NodeRef* = ref Node
