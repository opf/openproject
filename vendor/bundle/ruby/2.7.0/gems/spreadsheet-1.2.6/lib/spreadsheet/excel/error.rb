module Spreadsheet
  module Excel
##
# This class encapsulates Excel Error-Codes
class Error
  attr_reader :code
  ERROR_VALUES = {
    0x00 => '#NULL!',  # Intersection of two cell ranges is empty
    0x07 => '#DIV/0!', # Division by zero
    0x0F => '#VALUE!', # Wrong type of operand
    0x17 => '#REF!',   # Illegal or deleted cell reference
    0x1D => '#NAME?',  # Wrong function or range name
    0x24 => '#NUM!',   # Value range overflow
    0x2A => '#N/A!',   # Argument or function not available
  }
  def initialize code
    @code = code
  end
  ##
  # The String value Excel associates with an Error code
  def value
    ERROR_VALUES.fetch @code, '#UNKNOWN'
  end
end
  end
end
