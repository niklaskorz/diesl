import nimscripter/nimscripted

exportCode:
  type
    DbHandle* = object of RootObj
    DbTable* = object of RootObj
      name*: string
      columnNames*: seq[string]
      columnTypes*: seq[string]
