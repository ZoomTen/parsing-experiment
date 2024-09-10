switch("define", "useMalloc")
switch("define", "release")
#switch("define", "nimPreviewSlimSystem")
switch("threads", "off")
switch(when NimMajor >= 2: "mm" else: "gc", "orc")
switch("define", "lto")

switch("nimcache", "nc")
switch("panics", "on")
switch("define", "noSignalHandler")
switch("passC", "-g")
switch("opt", "none")

switch("debugger", "native")
