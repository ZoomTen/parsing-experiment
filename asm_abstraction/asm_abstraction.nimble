# Package

version = "0.1.0"
author = "Anonymous"
description = "A new awesome nimble package"
license = "MIT"
srcDir = "src"
bin = @["asm_abstraction"]

requires "nim >= 2.0.4"
requires "pretty"

before build:
  withDir("../lemon"):
    # compile Lemon
    if findExe("./lemon") == "":
      exec("make")
    # compile the grammar stuff
    exec("./lemon " & thisDir() & "/src/grammar/grammar.y")

after clean:
  # clean the grammar stuff
  withDir("./src/grammar"):
    for ext in [".c", ".h", ".out"]:
      rmFile("grammar" & ext)
