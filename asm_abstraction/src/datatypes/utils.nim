{.used.}

import std/parseutils
import ./shared

proc make_node*(kind: NodeKind): NodeRef {.cdecl, exportc.} =
  var r = new(Node)
  r.kind = kind
  return r

proc assign_node_ref_generic*(a: ptr NodeRef, b: NodeRef): void {.cdecl, exportc.} =
  a[] = b

proc assign_cstr_generic*(a: ptr cstring, b: cstring): void {.cdecl, exportc.} =
  a[] = b

proc add_node_generic*(a: ptr seq[NodeRef], b: NodeRef): void {.cdecl, exportc.} =
  a[].add(b)

proc number_from_hex_token*(a: Token): cint {.cdecl, exportc.} =
  # assume that the token starts with a '$'
  var i: cint
  discard ($a.word)[1 ..^ 0].parseHex(i)
  return i
