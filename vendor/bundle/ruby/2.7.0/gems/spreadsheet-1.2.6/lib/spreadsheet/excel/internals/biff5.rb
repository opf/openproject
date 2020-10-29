module Spreadsheet
  module Excel
    module Internals
##
# Binary Formats and other configurations internal to Biff5. This Module is
# likely to be expanded as Support for older Versions of Excel grows.
module Biff5
  BINARY_FORMATS = {
    :dimensions => 'v5',
  }
  def binfmt key # :nodoc:
    BINARY_FORMATS.fetch key do super end
  end
end
    end
  end
end
