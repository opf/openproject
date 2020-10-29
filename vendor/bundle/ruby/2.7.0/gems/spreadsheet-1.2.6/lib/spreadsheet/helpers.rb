module Spreadsheet
  module Helpers
    def rcompact(array)
      while !array.empty? && array.last.nil?
        array.pop
      end
      array
    end
    module_function :rcompact
  end
end
