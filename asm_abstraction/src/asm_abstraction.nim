import std/syncio
when not defined(nimPreviewSlimSystem):
  import pretty
import ./datatypes/[shared, utils]
import ./grammar/[lexer, invoke_lemon]

proc `standard malloc`*(s: csize_t): pointer {.cdecl, importc: "malloc".}

proc `standard free`*(s: pointer): void {.cdecl, importc: "free".}

proc `convert to asm`(p: NodeRef): void =
  if p == nil:
    return
  when not defined(nimPreviewSlimSystem):
    print p

proc main(): int =
  # First, initialize the lexer by using a compile-time string for now
  let str = `read file`("src/test_files/small.txt")
  var lxs = `init lexer from` str

  # Prepare the token bin, because I'm gonna print it for test purposes
  var tokens: seq[Token] = @[]

  let parser = `allocate Lemon parser using` `standard malloc`

  # Go through all the tokens...
  var token = lxs.`get next token`()
  while token.kind != Invalid:
    # ...adding them to the bin in the process.
    tokens.add token
    parser.`parse token with Lemon parser`(
      cast[cint](token.kind), token, lxs.internal.addr
    )
    token = lxs.`get next token`()
  # We either got an invalid token or it really is the end of the buffer.
  parser.`end Lemon parsing`(lxs.internal.addr)

  # Print the tokens we have so far.
  when not defined(nimPreviewSlimSystem):
    print(tokens)
  
  lxs.internal.tree.`convert to asm`()

  # Finally, do cleanup
  parser.`destroy Lemon parser using` `standard free`
  for i in tokens.mitems():
    if i.word != nil:
      dealloc i.word
  return 0

when `is main module`:
  quit(main())
