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
    Identifier
    Sub
    OpenParen
    CloseParen
    Asm
    AsmLiteral
    Register

  # State of the lexer that can be accessed from Lemon
  # Must match corresponding struct in ./shared.h
  InternalState* {.byref, importc, header: sharedHeader.} = object

  # Incidental token
  # Must match corresponding struct in ./shared.h
  Token* {.bycopy, importc, header: sharedHeader.} = object
    kind*: TokenKind
    position*: cint
    length*: cint
    word*: cstring
