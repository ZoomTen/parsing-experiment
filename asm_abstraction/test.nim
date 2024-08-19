import pretty
import std/syncio

{.compile:"grammar.c".}

proc `standard malloc`(s: csize_t): pointer {.cdecl, importc: "malloc".}

proc `standard free`(s: pointer): void {.cdecl, importc: "free".}

proc `allocate Lemon parser using`(
  `malloc proc`: proc(s: csize_t): pointer {.cdecl.}
): pointer {.cdecl, importc: "ParseAlloc".}

proc `destroy Lemon parser using`(
  which: pointer, `free proc`: proc(s: pointer): void {.cdecl.}
): void {.cdecl, importc: "ParseFree".}

type
  TokenKind {.size: sizeof(cint).} = enum
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

  InlineHacks = enum
    None
    `Got asm`
    `Got asm and open bracket`

  # State of the lexer that can be accessed from Lemon
  InternalState {.byref, exportc.} = object

  # Lexer's state from the Nim side
  LexerState = object
    buffer: string
    position: int
    column: int
    line: int
    `inline hacks`: InlineHacks
    internal: InternalState

  # Incidental token
  Token {.bycopy, exportc.} = object
    kind: TokenKind
    position: cint
    length: cint
    word: cstring

proc `parse token with Lemon parser`(
  which: pointer, `token id`: cint, `where to`: Token, `extra arg`: InternalState
): void {.cdecl, importc: "Parse".}

template `end Lemon parsing`(which: pointer): void =
  which.`parse token with Lemon parser`(0, Token(), InternalState())

proc `get next token`(lexer: var LexerState): Token =
  const
    `valid identifiers` = {'a' .. 'z'} + {'A' .. 'Z'} + {'0' .. '9'} + {'_'}
    `valid identifier starting characters` = `valid identifiers` - {'0' .. '9'}
    `whitespace characters` = {'\r', '\n', '\t', ' '}
    `valid hex characters` = {'0' .. '9'} + {'a' .. 'f'} + {'A' .. 'F'}

  template `current char`(): char =
    lexer.buffer[lexer.position]

  template `advance buffer`(): void =
    lexer.position += 1
    lexer.column += 1

  template `advance buffer and length`(): void =
    `advance buffer`()
    result.length += 1

  template `copy token from`(`start position`: int): cstring =
    let s = cast[cstring](alloc0impl(result.length + 1))
    copyMem(s[0].addr, lexer.buffer[`start position`].addr, result.length)
    s

  template `buffer is not exhausted`(): bool =
    lexer.position < lexer.buffer.len

  template `characters are too much to ask`(amount: int): bool =
    lexer.position + amount > (lexer.buffer.len - 1)

  template `notify error`(error: string) =
    stderr.writeLine error, " at ", $lexer.line, ":", $lexer.column

  # initialize
  result.kind = Invalid
  result.position = lexer.position.cint
  result.length = 0
  result.word = nil

  if (
    `buffer is not exhausted`() and lexer.`inline hacks` == `Got asm and open bracket`
  ):
    let `start position` = lexer.position
    while `current char`() != '}':
      `advance buffer and length`()
    lexer.`inline hacks` = None
    result.kind = AsmLiteral
    result.word = `copy token from` `start position`
    return result

  # ignore whitespace
  while (let s = `current char`(); s in `whitespace characters`):
    `advance buffer`()
    if s == '\n':
      lexer.column = 1
      lexer.line += 1

  result.position = lexer.position.cint
  let `start position` = lexer.position
  case `current char`()
  of '$': # HexNumber (TK_HEX_NUMBER)
    if 1.`characters are too much to ask`:
      `notify error` "Expected at least 1 character after $ "
      return result
    # scan as far as the lexer can see for numbers
    `advance buffer and length`()
    while (`buffer is not exhausted`() and `current char`() in `valid hex characters`):
      `advance buffer and length`()
      discard
    result.kind = HexNumber
    result.word = `copy token from` `start position`
  of ':': # Colon (TK_COLON)
    `advance buffer and length`()
    result.kind = Colon
    result.word = `copy token from` `start position`
  of '{': # OpenBracket (TK_OPEN_BRACKET)
    `advance buffer and length`()
    result.kind = OpenBracket
    result.word = `copy token from` `start position`
    if lexer.`inline hacks` == `Got asm`:
      lexer.`inline hacks` = `Got asm and open bracket`
  of '}': # CloseBracket (TK_CLOSE_BRACKET)
    `advance buffer and length`()
    result.kind = CloseBracket
    result.word = `copy token from` `start position`
  of '(':
    `advance buffer and length`()
    result.kind = OpenParen
    result.word = `copy token from` `start position`
  of ')':
    `advance buffer and length`()
    result.kind = CloseParen
    result.word = `copy token from` `start position`
  of '"': # String (TK_STRING)
    if 1.`characters are too much to ask`:
      `notify error` "Expected at least 1 character after \""
      return result
    `advance buffer and length`()
    var `got matching quote` = false
    while `buffer is not exhausted`():
      if `current char`() == '"':
        `got matching quote` = true
        `advance buffer and length`()
        break
      `advance buffer and length`()
    result.kind = String
    result.word = `copy token from` `start position`
  of `valid identifier starting characters`:
    var `temp keyword` = $`current char`()
    `advance buffer`()
    while (`buffer is not exhausted`() and `current char`() in `valid identifiers`):
      `temp keyword`.add `current char`()
      `advance buffer`()
    result.word = cast[cstring](alloc0impl(`temp keyword`.len + 1))
    result.word.copyMem(`temp keyword`[0].addr, `temp keyword`.len)
    result.length = `temp keyword`.len.cint
    result.kind = (
      case `temp keyword`
      of "sub": Sub
      of "asm": Asm
      else: Identifier
    )
    if result.kind == Asm:
      lexer.`inline hacks` = `Got asm`
  else:
    discard
  return result

proc main(): int =
  const buf = staticRead("small.txt")
  var lxs = LexerState(buffer: buf, column: 1, line: 1)

  let parser = `allocate Lemon parser using` `standard malloc`
  var
    tokens: seq[Token] = @[]
    token = lxs.`get next token`()
  while token.kind != Invalid:
    tokens.add(token)
    if token.kind != Invalid:
      parser.`parse token with Lemon parser`(
        cast[cint](token.kind), token, lxs.internal
      )
    token = lxs.`get next token`()
  parser.`end Lemon parsing`()
  print(tokens)
  for i in tokens.mitems():
    if i.word != nil:
      dealloc(i.word)
  parser.`destroy Lemon parser using` `standard free`

  return 0

when isMainModule:
  quit(main())
