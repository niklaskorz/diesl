# The DieSL Language

## Documentation

The documentation of the DieSL API can be found [here](https://pvs-hd.gitlab.io/ot/diesl/documentation/).
In particular, see the [documentation for string operations](https://pvs-hd.gitlab.io/ot/diesl/documentation/diesl/operations/strings.html).

## Running the demo

First, download and extract the [latest build of the demo](https://gitlab.com/pvs-hd/ot/diesl/-/jobs/artifacts/develop/download?job=build%20demo).
Then, you can run the demo binary with one of the example scripts from the `example/` folder or with any other DieSL script file you have written.
You may also modify the demo data in `example/data.csv`.
While you may change all rows and also add or remove rows, you currently can't change the structure of the demo data without updating the code of the demo in `src/diesl.nim`.

The demo binary supports two modes: `direct` and `views`.
In `direct` mode, the DieSL operations are translated into SQL `UPDATE` statements and the demo table is queried and printed directly.
In `views` mode, the operations are translated into SQL `CREATE VIEW` statements and the last created view is queried and printed.

Example:

```
# Linux
./diesl.out direct examples/basic_nim.diesl
# Windows
.\diesl.exe direct examples\basic_nim.diesl
```

If you want to build the project from source instead of running the prebuilt binaries (e.g., if you want to run the DieSL demo on macOS), make sure you have `nim` and `nimble` installed. Then run the following from the root directory of the repository:

```
nimble update
# nimble run -- <mode> <file>
nimble run -- direct examples/nim.diesl
```

## Writing DieSL Scripts

DieSL is based on NimScript and thus supports most of Nim's language features.
To express data manipulations, DieSL offers two APIs: a programmatic API that uses Nim's function calls to stay as close to the language as possible, and a natural API that is based on a macro block called `change`.

### The Nim Way

In the programmatic API, tables can be accessed as `db.tableName` and columns as `db.tableName.columnName`. To assign values to a column, use the assignment operator `db.tableName.columnName = newValue`.
You can also assign to multiple columns at once, for example when you want to assign the same value to multiple columns (`db.tableName[columnA, columnB] = "same value!"`) or use an operation that returns multiple values (`db.tableName[columnA, columnB] = db.tableName.columnC.split(",")`).

Here is an overview of supported operations (executable example in `examples/all_nim.diesl`):

```nim
# Store a value in table "students" column "name"
db.students.name = "Hello world"
# Load a value from column "firstName" and store in "name"
db.students.name = db.students.firstName
# Concat two columns with a space inbetween and store in name
db.students.name = db.students.firstName & " " & db.students.secondName
# Trim whitespace character on left and right of name column
db.students.name = db.students.name.trim() # or .trim(both)
# Trim whitespace character on left of name column
db.students.name = db.students.name.trim(left)
# Trim whitespace character on right of name column
db.students.name = db.students.name.trim(right)
# Take only characters from zero-based index 2 to 5 from name
db.students.name = db.students.name[2..5]
# Replace firstName in name with "Mr. "
db.students.name = db.students.name.replace(db.students.firstName, "Mr. ")
# Replace pairs in column name
db.students.name = db.students.name.replaceAll(@{
  db.students.firstName: "Mr. ",
  db.students.secondName: "Hello"
})
# Replace value in column with empty string
db.students.name = db.students.name.remove("some swear word")
# Lower case the whole string
db.students.name = db.students.name.toLower()
# Upper case the whole string
db.students.name = db.students.name.toUpper()
# Extract first occurence of pattern
db.students.name = db.students.name.extractOne("{hashtag}")
# Extract groups with pattern
db.students[firstName, secondName] = db.students.name.extractAll("([a-z]+) ([a-z]+)")
# Replace pattern in name with "Mr. "
db.students.name = db.students.name.patternReplace("{email}", "Mr. ")
# Replace pattern pairs in column "name"
db.students.name = db.students.name.patternReplaceAll(@{
  "{email}": "Mr. ",
  "[a-z]+": "Hello",
  "{hashtag}": "there",
})
# Split column
db.students[firstName, secondName] = db.students.name.split(" ")
```

### The Natural Way

To make it easier to get started with DieSL, our naturally looking macro-based API can be used instead.
This allows using DieSL even if you are unfamiliar with programming.
The base of this API is the `change` block that operates on a table, for example:

```nim
# Modify table "students"
change db.students:
  # Remove whitespace from end of column "firstName"
  trim ending of firstName
  # Remove any occurence of "bad word" in column "secondName"
  remove "bad word" from secondName
```

If you only want to apply operations to a single column, you can also use this shorter variant:

```nim
# Modify column "firstName" of table "students"
change firstName of db.students:
  # Remove whitespace from end of column
  trim ending
  # Remove any occurence of "bad word" in column
  remove "bad word"
```

Here is an overview of supported operations (executable example in `examples/all_natural.diesl`):

```nim
change db.students:
  # Trim whitespace character on left and right of name column
  trim name
  # Trim whitespace character on left of name column
  trim beginning of name
  # Trim whitespace character on right of name column
  trim ending of name
  # Take only characters from 1-based index 3 to 6 (zero-based index 2 to 5) from name
  take 3 to 6 from name
  # Replace "Señor " in name with "Mr. "
  replace "Señor " with "Mr. " in name
  # Replace pairs in column name
  replace in name:
    "Señor " with "Mr. "
    "Hello" with "there"
  # Replace value in column with empty string
  remove "some swear word" from name
  # Extract first occurence of pattern
  extract "{hashtag}" from name
  # or:
  extract hashtag from name
  # Extract groups with pattern
  extract "([a-z]+) ([a-z]+)" from name into firstName and secondName
  # Replace pattern in name with "Mr. "
  replace pattern "{email}" with "Mr. " in name
  # Replace pattern pairs in column "name"
  replace patterns in name:
    "{email}" with "Mr. "
    "[a-z]+" with "<secondName>"
    "{hashtag}" with "there"
  # Split column
  split name on " " into firstName, secondName
```

## Running DieSL Scripts

To run DieSL scripts inside your own application, use this repository as a package through nimble:

```nim
requires "https://gitlab.com/pvs-hd/ot/diesl.git >= 0.4.0"

Then, use the DieSL modules:

```nim
import db_sqlite
import diesl
# needed for functions like pattern extraction
import diesl/extensions/sqlite

# Open your sqlite database
let db = open(...)

# Install DieSL sqlite extensions
db.installCommands()

# Define your database schema
let schema = newDatabaseSchema({ ... })

# Read your user's script
let scriptSource = ...

# Run script and receive result
let exportedOperations = runScript(scriptSource, schema)

# Option A: Translate operations to Sqlite UPDATE statements
let queries = exportedOperations.toSqlite()

# Option B: Translate operations to Sqlite CREATE VIEW statements
let (queries, tableAccessMap, views) = exportedOperations.toSqliteViews(schema)
# tableAccessMap.getTableAccessName(tableName) returns the last view name created for a certain table

# Run generated queries
for query in queries:
  db.exec(query)

# Close your sqlite database
db.close()
```

## How it works

DieSL code consists of one or more change macros (which is defined in [transpilation.nim](src/diesl/syntax/transpilation.nim)). When a script is passed into the [runScript](src/diesl/script.nim#L127) function it is executed in a NimVM where the macro is expanded. The [change macro](src/diesl/syntax/transpilation.nim#L58) looks for all Nim statements that match a pattern of the DieSL commands and translates them to their Nim counterpart - all Nim statements inbetween stay the same. After that the code is evaluated by the Nim interpreter. __Important:__ This does not execute any changes on the database it just creates an [object](src/diesl/operations/base.nim#L16) representing what operations should take place. This object is then retrieved from the VM and translated to the target language (currently only SQLite).

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

The natural syntax of Diesl is defined in [transpilation.nim](src/diesl/syntax/transpilation.nim). To add a new one it needs to be added in [transpileCommand](src/diesl/syntax/transpilation.nim#15). For parsing we use [pattern matching](https://nim-lang.github.io/fusion/src/fusion/matching.html) on the AST. If the command cannot be parsed it is important that the old command is returned instead per default. At the moment you need to account for both variants of a operation (one where the column is given directly and one where the column is given in the first line of the change block), you can see this in the other operations as well. We tried our hand at smarter solutions and failed to problems with how Nim's type system handles generics.

Currently, the project's sole backend targets SQLite.
To this end, the functionality for each DieslOperation can be implemented directly in SQLite's SQL dialect, or compiled into a native binary, loaded into SQLite at startup and accordingly referenced.

### Simple Implementation: SQLite's SQL dialect

Continuing the running example of trimming strings, the functionality can be implemented by expanding the definition of the [toSqlite](src/diesl/backends/sqlite.nim#L27) procedure.
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

First, the scalar [padding](src/diesl/extensions/sqlite.nim#L37) procedure is defined in Nim.
It is important that the procedure have the `exportToSqlite3` pragma applied, so that [installCommands](src/diesl/extensions/sqlite.nim#L8) can register the procedures during initialisation.
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
