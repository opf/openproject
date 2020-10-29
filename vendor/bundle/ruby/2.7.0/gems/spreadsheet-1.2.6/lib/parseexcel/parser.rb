require 'parseexcel'

module Spreadsheet
  module ParseExcel # :nodoc: all
    class Parser
      def parse path
        Spreadsheet.open path
      end
    end
  end
end
