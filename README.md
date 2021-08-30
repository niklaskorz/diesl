# The DieSL Language

## Documentation

The documentation of the DSL API can be found here: https://pvs-hd.gitlab.io/ot/diesl/documentation/

## Test Coverage

The unit test coverage report can be found here: https://pvs-hd.gitlab.io/ot/diesl/coverage/



# Tutorial

## Extending DieSL with New Operations

DieSL's operations are defined by the [DieslOperation](src/diesl/operations/types.nim#L49) object.
Specifically, this type is an enum that is controlled by the [DieslOperationType](src/diesl/operations/types.nim#L6); each DieslOperationType indicates a unique semantic, and as such, each DieslOperation variant can store different data according thereto.


### Defining a new DieslOperation

For example, if a new operation for trimming strings is to be introduced, a new DieslOperationType called `dotTrim` can be defined

```nim
type DieslOperationType* = enum
  dotStore
  dotLoad
  ...
  dotTrim
```

which enables the DieslOperation object to be accordingly extended:
```nim
type DieslOperation* = ref object
  case kind*: DieslOperationType
    of dotStore:
      ...
    of dotLoad:
      ...
    of dotTrim:
      # string data that is to be trimmed
      trimValue*: DieslOperation
      # from which side should the string be trimmed
      trimDirection*: TextDirection
```

DieSL defines multiple visitors on DieslOperations that have to be extended when a new variant is introduced, namely [withAccessIndex](src/diesl/operations/accessindex.nim#L5), [collectTableAccesses](src/diesl/operations/boundaries.nim#L5), [collectLoads](src/diesl/operations/optimizations.nim#L8) and [toDataType](src/diesl/operations/types.nim#L122).


Currently, the project's sole backend targets SQLite.
To this end, the functionality for each DieslOperation can be implemented directly in SQLite's SQL dialect, or compiled into a native binary, loaded into SQLite at startup and accordingly referenced.


### Simple Implementation: SQLite's SQL dialect

Continuing the running example of trimming strings, the functionality can be implemented by expanding the definition of the [toSqlite](src/diesl/backends/sqlite.nim#L12) procedure.
In this case, SQLite's SQL dialect offers built-in scalar functions from [trimming from the left](https://www.sqlite.org/lang_corefunc.html#ltrim), [from the right](https://www.sqlite.org/lang_corefunc.html#rtrim) and from [both sides](https://www.sqlite.org/lang_corefunc.html#trim).
As such, the implementation for trimming can simply return an SQL string containing the function call to the correct trimmer:

```nim
proc toSqlite*(op: DieslOperation): string =
  case op.kind:
    of dotStore:
      ...
    of dotLoad:
      ...
    of dotTrim:
      # Derive which kind of trimming is desired
      let trimFunction = case op.trimDirection:
        of TextDirection.left:
          "LTRIM"
        of TextDirection.right:
          "RTRIM"
        of TextDirection.both:
          "TRIM"

      # This is an interpolated string, substituting expressions
      # into their corresponding placeholders within the string.
      fmt"{trimFunction}({op.trimValue.toSqlite})"

      # The `op.trimValue.toSqlite` expression recurses into the
      # `trimValue` member for its own SQL generation
```


### Advanced Implementation: exportToSqlite3

More complex actions are tricky to implement or cannot be solely implemented in SQL.
To this end, [extension methods](src/diesl/extensions/sqlite.nim) can be implemented.
This approach was deemed viable for string padding, where Nim provides corresponding methods in the standard library and SQLite does not.

First, the scalar [padding](src/diesl/extensions/sqlite.nim#26) procedure is defined in Nim.
It is important that the procedure have the `exportToSqlite3` pragma applied, so that [installCommands](src/diesl/extensions/sqlite.nim#8) can register the procedures during initialisation.
Finally, the SQLite codegen shall generate SQL that calls the padding procedure as if it were a builtin SQLite function:

```nim
proc toSqlite*(op: DieslOperation): string {.gcSafe.} =
  case op.kind:
    of dotPadString:
      # Derive direction and character padding variables from the operation
      let direction = ...
      let padWith = ...

      # Generate the corresponding SQL call
      fmt"padding({op.padStringValue.toSqlite}, {direction}, {op.padStringCount}, {padWith})"
```
