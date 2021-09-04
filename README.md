# The DieSL Language

## Documentation
The documentation of the DSL API can be found here: https://pvs-hd.gitlab.io/ot/diesl/documentation/

## Running the demo

First, download and extract the [latest build of the demo](https://gitlab.com/pvs-hd/ot/diesl/-/jobs/artifacts/develop/download?job=build%20demo).
Then, you can run the demo binary with one of the example scripts from the `example/` folder or with any other DieSL script file you have written.
The demo binary supports two modes: `direct` and `views`.
In `direct` mode, the DieSL operations are translated into SQL `UPDATE` statements and the demo table is queried and printed directly.
In `views` mode, the operations are translated into SQL `CREATE VIEW` statements and the last created view is queried and printed.
Example:

```
# Linux
./diesl examples/nim.diesl
# Windows
.\diesl.exe examples\nim.diesl
```

## How it works

DieSL code consists of one or more change macros (which is defined in [transpilation.nim](src/diesl/syntax/transpilation.nim)). When a script is passed into the [runScript](src/diesl/script.nim#L127) function it is executed in a NimVM where the macro is expanded. The [change macro](src/diesl/syntax/transpilation.nim#L304) looks for all Nim statements that match a pattern of the DieSL commands and translates them to their Nim counterpart - all Nim statements inbetween stay the same. After that the code is evaluated by the Nim interpreter. __Important:__ This does not execute any changes on the database it just creates an [object](src/diesl/operations/base.nim#L16) representing what operations should take place. This object is then retrieved from the VM and translated to the target language (currently only SQLite).

## Repository Structure

Tests are located in the tests folder (duh). All library logic is implemented under `src/diesl`.

- backends: Anything related to SQL generation goes here
- compat: Anything related to compability with other modules goes here (things like conversion functions)
- extensions: Everything here will be compiled to C and registered to SQLite and can be used in queries
- transpilation.nim: Contains everything for the parsing of the natural syntax
- operations: Defines the very important operation datatype and its functions. A operation represents anything that can be done in DieSL.
- script.nim: Takes care of executing DieSL script in the NimVM and retrieving the operations from there

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


### Adding Syntax for the new Operation

The natural syntax of Diesl is defined in [transpilation.nim](src/diesl/syntax/transpilation.nim). To add a new one it needs to be added in [transpileCommand](src/diesl/syntax/transpilation.nim#L263). For parsing we use [pattern matching](https://nim-lang.github.io/fusion/src/fusion/matching.html) on the AST. If the command cannot be parsed it is important that the old command is returned instead per default. At the moment you need to account for both variants of a operation (one where the column is given directly and one where the column is given in the first line of the change block), you can see this in the other operations as well. We tried our hand at smarter solutions and failed to problems with how Nim's type system handles generics.

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


## Side Projects

- [Making Nim functions available to SQLite](https://github.com/niklaskorz/nim-exporttosqlite3/)
- [Tracking TODOs in the project](https://github.com/preslavmihaylov/todocheck/pull/160)



## Accounting

* Niklas Korz: 40% + aforementioned exportage library, in particular:
  * SQL generation and optimization
* Benjamin Sparks: 30%, in particular:
  * String and Regex operations + Documentation
* Samuel Melm: 30%, in particular:
  * Natural Syntax Parsing (macros)

All aspects of requirements, main implementation, testing etc., were shared amongst the team and assigned during meetings in the Issue Tracker.
Accordingly, this means that the responsibility of main and test code was shared equally.
