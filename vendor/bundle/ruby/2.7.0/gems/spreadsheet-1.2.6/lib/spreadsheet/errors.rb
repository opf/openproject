module Spreadsheet
  # Custom errors raised by this gem, not errors from Excel
  module Errors
    BaseError           = Class.new(StandardError)

    # A codepage not stored in Spreadsheet::Internals::CODEPAGES
    UnknownCodepage     = Class.new(BaseError)
    # The encoding can be known, but not supported by Ruby
    UnsupportedEncoding = Class.new(BaseError)
  end
end
