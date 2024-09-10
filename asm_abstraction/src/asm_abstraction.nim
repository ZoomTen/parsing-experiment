include ./gcc14_fix

when NimMajor >= 2:
  import std/syncio
import std/strutils
when not defined(nimPreviewSlimSystem):
  import pretty
import ./datatypes/[shared, utils]
import ./grammar/[lexer, invoke_lemon]

proc `standard malloc`*(s: csize_t): pointer {.cdecl, importc: "malloc".}

proc `standard free`*(s: pointer): void {.cdecl, importc: "free".}

proc `convert to asm`(p: NodeRef): void =
  if p == nil:
    return
  case p.kind
  of Program:
    for item in p.program_items:
      item.`convert to asm`()
  of SectionBlock:
    let
      `section name` = p.section_name
      `ROM address` = p.at_address
    assert `section name` != nil
    assert `ROM address` != nil
    assert `ROM address`.kind == NodeKind.RomAddress
    assert `ROM address`.address in 0x0000 .. 0x7fff
    assert `ROM address`.bank in 0x00 .. 0xff
    if `ROM address`.bank == 0:
      assert `ROM address`.address in 0x0000 .. 0x3fff
    else:
      assert `ROM address`.address in 0x4000 .. 0x7fff

    `debug echo`(
      "SECTION \"" & $`section name` & "\", " &
        (if `ROM address`.bank == 0: "ROM0[$" else: "ROMX[$") &
        `ROM address`.address.`to hex`(4) & "]" & (
        if `ROM address`.bank > 0:
          ", BANK[$" & `ROM address`.bank.`to hex`(2) & "]"
        else:
          ""
      )
    )

    if p.section_content != nil and p.section_content.kind == SubAndDataList:
      for content in p.section_content.subs_datas:
        content.`convert to asm`()
  of SubAndDataList:
    for item in p.subs_datas:
      item.`convert to asm`()
  of SubBlock:
    assert p.sub_name != nil
    when false: # not ready yet!
      # disallow fallthrough
      assert p.sub_content != nil
    `debug echo`($p.sub_name & ":")
    if p.sub_content != nil:
      for item in p.sub_content.sub_items:
        item.`convert to asm`()
  of DataBlock:
    assert p.data_name != nil
    when false: # not ready yet!
      # disallow fallthrough
      assert p.data_content != nil
    `debug echo`($p.data_name & ":")
    if p.data_content != nil:
      for item in p.data_content.data_items:
        item.`convert to asm`()
  of AsmLiteralNode:
    assert p.asm_content != nil
    # bonus: "prettify" lines..
    for i in ($p.asm_content).split('\n'):
      let x = i.strip()
      if x.len > 0:
        `debug echo`(
          if x[^1] == ':':
            x
          else:
            "\t" & x
        )
  of Assignment:
    let
      `left hand side` = p.assign_target
      `right hand side` = p.assign_value

    assert `left hand side`.kind in [NodeKind.RegisterNode, NodeKind.IdentifierNode] # TODO
    assert `right hand side`.kind in [NodeKind.RegisterNode, NodeKind.IdentifierNode] # TODO

    case `left hand side`.kind
    of RegisterNode:
      case `right hand side`.kind
      of RegisterNode:
        `debug echo`(
          "\tld " & ($`left hand side`.reg_name)[1 ..^ 1] & ", " &
            ($`right hand side`.reg_name)[1 ..^ 1]
        )
      else:
        discard
    else:
      discard
  else:
    return

proc main(): int =
  let buffer = `read file`("src/test_files/small.txt")
  var `lex state` = `init lexer from` buffer

  # Prepare the token bin, because I'm gonna print it for test purposes
  var tokens: seq[Token] = @[]

  let parser = `allocate Lemon parser using` `standard malloc`

  # Go through all the tokens...
  var token = `lex state`.`get next token`()
  while token.kind != Invalid:
    # ...adding them to the bin in the process.
    tokens.add token
    parser.`parse token with Lemon parser`(
      cast[cint](token.kind), token, `lex state`.internal.addr
    )
    token = `lex state`.`get next token`()
  # We either got an invalid token or it really is the end of the buffer.
  parser.`end Lemon parsing`(`lex state`.internal.addr)

  # Print the tokens we have so far.
  when not defined(nimPreviewSlimSystem):
    print(tokens)
    print(`lex state`.internal.tree)

  `lex state`.internal.tree.`convert to asm`()

  # Finally, do cleanup
  parser.`destroy Lemon parser using` `standard free`
  for i in tokens.mitems():
    if i.word != nil:
      dealloc i.word
  return 0

when `is main module`:
  quit(main())
