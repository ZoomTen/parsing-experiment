import ../datatypes/shared

type
  InlineHacks = enum
    None
    `Got asm`
    `Got asm and open bracket`

  # Lexer's state from the Nim side
  LexerState = object
    buffer: string
    position: int
    column: int
    line: int
    `inline hacks`: InlineHacks
    internal*: InternalState

const
  `valid identifiers` = {'a' .. 'z'} + {'A' .. 'Z'} + {'0' .. '9'} + {'_'}
  `valid identifier starting characters` = `valid identifiers` - {'0' .. '9'}
  `whitespace characters` = {'\r', '\n', '\t', ' '}
  `valid hex characters` = {'0' .. '9'} + {'a' .. 'f'} + {'A' .. 'F'}

proc `init lexer from`*(buffer: string): LexerState =
  return LexerState(buffer: buffer, column: 1, line: 1)

proc `get next token`*(lexer: var LexerState): Token =
  # initialize
  result.kind = Invalid
  result.position = lexer.position.cint
  result.length = 0
  result.word = nil

  template `current char`(): char =
    lexer.buffer[lexer.position]

  template `advance buffer`(): void =
    lexer.position += 1
    lexer.column += 1

  template `advance buffer and length`(): void =
    `advance buffer`()
    result.length += 1

  template `make a copy of string`(what: string): cstring =
    # Essentially a `strdup`.
    let s = cast[cstring](alloc0impl(what.len + 1))
    s[0].addr.copyMem(what[0].addr, what.len)
    s

  template `make a copy of token from`(`start position`: int): cstring =
    # Another `strdup`!
    let s = cast[cstring](alloc0impl(result.length + 1))
    s[0].addr.copyMem(lexer.buffer[`start position`].addr, result.length)
    s

  template `buffer not exhausted yet`(): bool =
    lexer.position < lexer.buffer.len

  template `characters are too much to ask`(amount: int): bool =
    lexer.position + amount > (lexer.buffer.len - 1)

  template `notify error`(error: string) {.dirty.} =
    stderr.writeLine error, " at ", $`starting line`, ":", $`starting column`

  template `save starting positions`() {.dirty.} =
    let
      `start position` = lexer.position
      `starting line` = lexer.line
      `starting column` = lexer.column

  if lexer.`inline hacks` == `Got asm and open bracket`:
    # Bypass all the normal logic, because I'm parsing this entire thing
    # so I can just include it wholesale in the output, like Nim's {.emit.}.
    `save starting positions`()
    var `got ending bracket` = false
    while `buffer not exhausted yet`():
      # Stop when the lexer encounters a closing bracket.
      if `current char`() == '}':
        `got ending bracket` = true
        break
      `advance buffer and length`()
    if not `got ending bracket`:
      `notify error` "Unterminated ASM literal starting"
      return result
    # Reset the state of the lexer
    lexer.`inline hacks` = None
    result.kind = AsmLiteral
    result.word = `make a copy of token from` `start position`
    return result

  # Bypass whitespace
  while (let s = `current char`(); s in `whitespace characters`):
    `advance buffer`()
    if s == '\n': # I assume Unix or DOS files
      lexer.column = 1
      lexer.line += 1

  result.position = lexer.position.cint
  `save starting positions`()
  case `current char`()
  # HexNumber (TK_HEX_NUMBER)
  of '$':
    if 1.`characters are too much to ask`:
      `notify error` "Expected at least 1 character after $ "
      return result
    # scan as far as the lexer can see for numbers
    `advance buffer and length`()
    while `buffer not exhausted yet`():
      if `current char`() in `valid hex characters`:
        `advance buffer and length`()
      else:
        break
    result.kind = HexNumber
    result.word = `make a copy of token from` `start position`
  # Colon (TK_COLON)
  of ':':
    `advance buffer and length`()
    result.kind = Colon
    result.word = `make a copy of token from` `start position`
  # OpenBracket (TK_OPEN_BRACKET)
  of '{':
    `advance buffer and length`()
    result.kind = OpenBracket
    result.word = `make a copy of token from` `start position`
    if lexer.`inline hacks` == `Got asm`:
      lexer.`inline hacks` = `Got asm and open bracket`
  # CloseBracket (TK_CLOSE_BRACKET)
  of '}':
    `advance buffer and length`()
    result.kind = CloseBracket
    result.word = `make a copy of token from` `start position`
    # OpenParen (TK_OPEN_PAREN)
  of '(':
    `advance buffer and length`()
    result.kind = OpenParen
    result.word = `make a copy of token from` `start position`
  # CloseParen (TK_CLOSE_PAREN)
  of ')':
    `advance buffer and length`()
    result.kind = CloseParen
    result.word = `make a copy of token from` `start position`
  # String (TK_STRING)
  of '"':
    if 1.`characters are too much to ask`:
      `notify error` "Expected at least 1 character after \""
      return result
    `advance buffer and length`()
    var `got matching quote` = false
    while `buffer not exhausted yet`():
      # if we see a matching quote, stop
      if `current char`() == '"':
        `got matching quote` = true
        `advance buffer and length`()
        break
      # otherwise, continue
      `advance buffer and length`()
    if not `got matching quote`:
      `notify error` "Unterminated string literal starting"
      return result
    result.kind = String
    result.word = `make a copy of token from` `start position`
  # Identifier (TK_IDENTIFIER)
  # Sub (TK_SUB)
  # Asm (TK_ASM)
  of `valid identifier starting characters`:
    var `temp keyword` = $`current char`()
    `advance buffer`()
    while `buffer not exhausted yet`():
      if `current char`() in `valid identifiers`:
        `temp keyword`.add `current char`()
        `advance buffer`()
      else:
        break
    result.word = `make a copy of string` `temp keyword`
    result.length = `temp keyword`.len.cint
    # Detect keywords, and the like.
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
