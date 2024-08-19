import ../datatypes/shared

{.compile: "grammar.c".}

proc `allocate Lemon parser using`*(
  `malloc proc`: proc(s: csize_t): pointer {.cdecl.}
): pointer {.cdecl, importc: "ParseAlloc".}

proc `destroy Lemon parser using`*(
  which: pointer, `free proc`: proc(s: pointer): void {.cdecl.}
): void {.cdecl, importc: "ParseFree".}

proc `parse token with Lemon parser`*(
  which: pointer, `token id`: cint, `where to`: Token, `extra arg`: InternalState
): void {.cdecl, importc: "Parse".}

template `end Lemon parsing`*(which: pointer): void =
  which.`parse token with Lemon parser`(0, Token(), InternalState())
