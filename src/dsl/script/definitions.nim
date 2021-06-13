import compiler/[nimeval, vm, vmdef]
import nimscripter/nimscripted
import db_sqlite
import backend/[data, table]
import shared
import ../db
import ../language

# Must appear before nimscripter import
exportCode:
  type
    DbHandle = object of RootObj
    DbTable = object of RootObj
      pColumnNames: seq[string]
      pColumnTypes: seq[string]
      pHandle: int
    DbColumn = object of RootObj
      pHandle: int

type ScriptContext* = ref object of RootObj
  db: DbConn
  tables: seq[Table]
  columns: seq[TableColumn]

proc newScriptContext*(db: DbConn): ScriptContext =
  ScriptContext(db: db, tables: @[])

proc storeTable(ctx: var ScriptContext, table: Table): int =
  ctx.tables.add(table)
  ctx.tables.len - 1

proc convert(ctx: ScriptContext, table: DbTable): Table =
  ctx.tables[table.pHandle]

proc convert(ctx: var ScriptContext, table: Table): DbTable =
  let handle = ctx.storeTable(table)
  DbTable(pColumnNames: table.columnNames, pColumnTypes: table.columnTypes,
      pHandle: handle)

proc storeColumn(ctx: var ScriptContext, column: TableColumn): int =
  ctx.columns.add(column)
  ctx.columns.len - 1

proc convert(ctx: ScriptContext, column: DbColumn): TableColumn =
  ctx.columns[column.pHandle]

proc convert(ctx: var ScriptContext, column: TableColumn): DbColumn =
  let handle = ctx.storeColumn(column)
  DbColumn(pHandle: handle)

let header = """
proc n_getTable(args: string): string = discard
proc getTable(db: DbHandle, name: string): DbTable =
  var args = ""
  db.addToBuffer(args)
  name.addToBuffer(args)
  let ret = n_getTable(args)
  var pos: BiggestInt = 0
  ret.getFromBuffer(DbTable, pos)

proc n_getColumn(args: string): string = discard
proc getColumn(table: DbTable, name: string): DbColumn =
  var args = ""
  table.addToBuffer(args)
  name.addToBuffer(args)
  let ret = n_getColumn(args)
  var pos: BiggestInt = 0
  ret.getFromBuffer(DbColumn, pos)

proc n_trim(args: string): string = discard
proc trim(column: DbColumn, direction: TextDirection = both): DbColumn =
  var args = ""
  column.addToBuffer(args)
  direction.addToBuffer(args)
  let ret = n_trim(args)
  var pos: BiggestInt = 0
  ret.getFromBuffer(DbColumn, pos)

proc n_substring(args: string): string = discard
proc substring(column: DbColumn, range: HSlice): DbColumn =
  var args = ""
  column.addToBuffer(args)
  range.addToBuffer(args)
  let ret = n_substring(args)
  var pos: BiggestInt = 0
  ret.getFromBuffer(DbColumn, pos)

proc `[]`(column: DbColumn, range: HSlice): DbColumn =
  column.substring(range)

proc n_replace(args: string): string = discard
proc replace(column: DbColumn, target, replacement: string): DbColumn =
  var args = ""
  column.addToBuffer(args)
  target.addToBuffer(args)
  replacement.addToBuffer(args)
  let ret = n_replace(args)
  var pos: BiggestInt = 0
  ret.getFromBuffer(DbColumn, pos)

proc n_replaceAll(args: string): string = discard
proc replaceAll(column: DbColumn, replacements: seq[(string, string)]): DbColumn =
  var args = ""
  column.addToBuffer(args)
  replacements.addToBuffer(args)
  let ret = n_replace(args)
  var pos: BiggestInt = 0
  ret.getFromBuffer(DbColumn, pos)

proc n_remove(args: string): string = discard
proc remove(column: DbColumn, target: string): DbColumn =
  var args = ""
  column.addToBuffer(args)
  target.addToBuffer(args)
  let ret = n_replace(args)
  var pos: BiggestInt = 0
  ret.getFromBuffer(DbColumn, pos)

proc n_add(args: string): string = discard
proc add(column: DbColumn, addition: string, direction: TextDirection): DbColumn =
  var args = ""
  column.addToBuffer(args)
  addition.addToBuffer(args)
  direction.addToBuffer(args)
  let ret = n_replace(args)
  var pos: BiggestInt = 0
  ret.getFromBuffer(DbColumn, pos)

proc `+`(column: DbColumn, addition: string): DbColumn =
  add(column, addition, right)

proc `+`(addition: string, column: DbColumn): DbColumn =
  add(column, addition, left)

proc n_toLower(args: string): string = discard
proc toLower(column: DbColumn): DbColumn =
  var args = ""
  column.addToBuffer(args)
  let ret = n_replace(args)
  var pos: BiggestInt = 0
  ret.getFromBuffer(DbColumn, pos)

proc n_toUpper(args: string): string = discard
proc toUpper(column: DbColumn): DbColumn =
  var args = ""
  column.addToBuffer(args)
  let ret = n_replace(args)
  var pos: BiggestInt = 0
  ret.getFromBuffer(DbColumn, pos)

{.experimental: "dotOperators".}

template `.`(db: DbHandle, tableName: untyped): DbTable =
  db.getTable(astToStr(tableName))

template `.`(table: DbTable, columnName: untyped): DbColumn =
  table.getColumn(astToStr(columnName))

let db = DbHandle()
"""

import nimscripter

proc initWithContext*(context: ScriptContext): InitFn =
  var ctx = context
  result = proc (
    intr: Interpreter, scriptName: string): string =
    intr.implementRoutine("*", scriptName, "n_getTable", proc(vm: VmArgs) =
      let args = vm.getString(0)
      var pos: BiggestInt = 0
      discard args.getFromBuffer(DbHandle, pos)
      let name = args.getFromBuffer(string, pos)
      let table = ctx.db.getTable(name)
      var ret = ""
      DbTable(
        pColumnNames: table.columnNames,
        pColumnTypes: table.columnTypes,
        pHandle: ctx.storeTable(table),
      ).addToBuffer(ret)
      vm.setResult(ret)
    )
    intr.implementRoutine("*", scriptName, "n_getColumn", proc(vm: VmArgs) =
      let args = vm.getString(0)
      var pos: BiggestInt = 0
      let table = ctx.convert(args.getFromBuffer(DbTable, pos))
      let name = args.getFromBuffer(string, pos)
      let column = table.getColumn(name)
      var ret = ""
      ctx.convert(column).addToBuffer(ret)
      vm.setResult(ret)
    )
    intr.implementRoutine("*", scriptName, "n_trim", proc(vm: VmArgs) =
      let args = vm.getString(0)
      var pos: BiggestInt = 0
      let column = args.getFromBuffer(DbColumn, pos)
      let direction = args.getFromBuffer(TextDirection, pos)
      let newColumn = ctx.convert(column).trim(direction)
      var ret = ""
      ctx.convert(newColumn).addToBuffer(ret)
      vm.setResult(ret)
    )
    intr.implementRoutine("*", scriptName, "n_substring", proc(vm: VmArgs) =
      let args = vm.getString(0)
      var pos: BiggestInt = 0
      let column = args.getFromBuffer(DbColumn, pos)
      let range = args.getFromBuffer(HSlice[int, int], pos)
      let newColumn = ctx.convert(column).substring(range)
      var ret = ""
      ctx.convert(newColumn).addToBuffer(ret)
      vm.setResult(ret)
    )
    intr.implementRoutine("*", scriptName, "n_replace", proc(vm: VmArgs) =
      let args = vm.getString(0)
      var pos: BiggestInt = 0
      let column = args.getFromBuffer(DbColumn, pos)
      let target = args.getFromBuffer(string, pos)
      let replacement = args.getFromBuffer(string, pos)
      let newColumn = ctx.convert(column).replace(target, replacement)
      var ret = ""
      ctx.convert(newColumn).addToBuffer(ret)
      vm.setResult(ret)
    )
    intr.implementRoutine("*", scriptName, "n_replaceAll", proc(vm: VmArgs) =
      let args = vm.getString(0)
      var pos: BiggestInt = 0
      let column = args.getFromBuffer(DbColumn, pos)
      let replacements = args.getFromBuffer(seq[(string, string)], pos)
      let newColumn = ctx.convert(column).replaceAll(replacements)
      var ret = ""
      ctx.convert(newColumn).addToBuffer(ret)
      vm.setResult(ret)
    )
    intr.implementRoutine("*", scriptName, "n_remove", proc(vm: VmArgs) =
      let args = vm.getString(0)
      var pos: BiggestInt = 0
      let column = args.getFromBuffer(DbColumn, pos)
      let target = args.getFromBuffer(string, pos)
      let newColumn = ctx.convert(column).remove(target)
      var ret = ""
      ctx.convert(newColumn).addToBuffer(ret)
      vm.setResult(ret)
    )
    intr.implementRoutine("*", scriptName, "n_add", proc(vm: VmArgs) =
      let args = vm.getString(0)
      var pos: BiggestInt = 0
      let column = args.getFromBuffer(DbColumn, pos)
      let addition = args.getFromBuffer(string, pos)
      let direction = args.getFromBuffer(TextDirection, pos)
      let newColumn = ctx.convert(column).add(addition, direction)
      var ret = ""
      ctx.convert(newColumn).addToBuffer(ret)
      vm.setResult(ret)
    )
    intr.implementRoutine("*", scriptName, "n_toLower", proc(vm: VmArgs) =
      let args = vm.getString(0)
      var pos: BiggestInt = 0
      let column = args.getFromBuffer(DbColumn, pos)
      let newColumn = ctx.convert(column).toLower()
      var ret = ""
      ctx.convert(newColumn).addToBuffer(ret)
      vm.setResult(ret)
    )
    intr.implementRoutine("*", scriptName, "n_toUpper", proc(vm: VmArgs) =
      let args = vm.getString(0)
      var pos: BiggestInt = 0
      let column = args.getFromBuffer(DbColumn, pos)
      let newColumn = ctx.convert(column).toUpper()
      var ret = ""
      ctx.convert(newColumn).addToBuffer(ret)
      vm.setResult(ret)
    )
    return header
