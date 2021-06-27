type
  DieslError* = object of CatchableError
  TableNotFoundError* = object of DieslError
  ColumnNotFoundError* = object of DieslError
  TypeMismatchError* = object of DieslError
