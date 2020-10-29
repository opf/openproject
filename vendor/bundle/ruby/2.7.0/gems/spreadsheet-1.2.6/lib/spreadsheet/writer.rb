module Spreadsheet
  ##
  # Parent Class for all Writers. Implements the copying of unmodified
  # Spreadsheet documents.
  class Writer
    def initialize io_or_path
      @io_or_path = io_or_path
    end
    def write workbook
      if @io_or_path.respond_to? :seek
        @io_or_path.binmode
        write_workbook workbook, @io_or_path
      else
        File.open(@io_or_path, "wb+") do |fh|
          write_workbook workbook, fh
        end
      end
    end
    private
    def write_workbook workbook, io
      reader = workbook.io
      unless io == reader
        reader.rewind
        data = reader.read
        io.rewind
        io.write data
      end
    end
  end
end
