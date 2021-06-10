import os
import nimscripter

proc runScript*(script: string): Option[Interpreter] =
  let home = os.getEnv("HOME")
  let stdPath = home / ".choosenim" / "toolchains" / "nim-1.4.6" / "lib"
  return loadScript(script, isFile = false, stdPath = stdPath)
