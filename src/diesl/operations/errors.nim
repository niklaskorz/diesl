type
  DieslError* = object of CatchableError
  DieslTableNotFoundError* = object of DieslError
  DieslColumnNotFoundError* = object of DieslError
  DieslDataTypeMismatchError* = object of DieslError
  DieselPatternNotFoundError* = object of DieslError