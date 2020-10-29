require 'spreadsheet/format'
require 'spreadsheet/encodings'

module Spreadsheet
  ##
  # The Workbook class represents a Spreadsheet-Document and is the entry point
  # for all Spreadsheet manipulation.
  #
  # Interesting Attributes:
  # #default_format:: The default format used for all cells in this Workbook.
  #                   that have no format set explicitly or in
  #                   Row#default_format or Worksheet#default_format.
  class Workbook
    include Spreadsheet::Encodings
    attr_reader :io, :worksheets, :formats, :fonts, :palette
    attr_accessor :active_worksheet, :encoding, :default_format, :version
    def initialize io = nil, opts={:default_format => Format.new}
      @worksheets = []
      @io = io
      @fonts = []
      @palette = {}
      @formats = []
      @formats_set = {}
      if @default_format = opts[:default_format]
        add_format @default_format
      end
    end
    ##
    # Add a Font to the Workbook. Used by the parser. You should not need to
    # use this Method.
    def add_font font
      @fonts.push(font).uniq! if font
      font
    end
    ##
    # Add a Format to the Workbook. If you use Row#set_format, you should not
    # need to use this Method.
    def add_format format
      if format && !@formats_set[format]
        @formats_set[format] = true
        @formats.push(format)
      end
      format
    end
    ##
    # Add a Worksheet to the Workbook.
    def add_worksheet worksheet
      worksheet.workbook = self
      @worksheets.push worksheet
      worksheet
    end
    ##
    # Delete a Worksheet from Workbook by it's index
    def delete_worksheet worksheet_index
      @worksheets.delete_at worksheet_index
    end
    ##
    # Change the RGB components of the elements in the colour palette.
    def set_custom_color idx, red, green, blue
      raise 'Invalid format' if [red, green, blue].find { |c| ! (0..255).include?(c) }

      @palette[idx] = [red, green, blue]
    end
    ##
    # Create a new Worksheet in this Workbook.
    # Used without options this creates a Worksheet with the name 'WorksheetN'
    # where the new Worksheet is the Nth Worksheet in this Workbook.
    #
    # Use the option <em>:name => 'My pretty Name'</em> to override this
    # behavior.
    def create_worksheet opts = {}
      opts[:name] ||= client("Worksheet#{@worksheets.size.next}", 'UTF-8')
      add_worksheet Worksheet.new(opts)
    end
    ##
    # Returns the count of total worksheets present.
    # Takes no arguments. Just returns the length of @worksheets array.
    def sheet_count
      @worksheets.length
    end
    ##
    # The Font at _idx_
    def font idx
      @fonts[idx]
    end
    ##
    # The Format at _idx_, or - if _idx_ is a String -
    # the Format with name == _idx_
    def format idx
      case idx
      when Integer
        @formats[idx] || @default_format || Format.new
      when String
        @formats.find do |fmt| fmt.name == idx end
      end
    end
    def inspect
      variables = (instance_variables - uninspect_variables).collect do |name|
        "%s=%s" % [name, instance_variable_get(name)]
      end.join(' ')
      uninspect = uninspect_variables.collect do |name|
        var = instance_variable_get name
        "%s=%s[%i]" % [name, var.class, var.size]
      end.join(' ')
      sprintf "#<%s:0x%014x %s %s>", self.class, object_id,
                                     variables, uninspect
    end
    def uninspect_variables # :nodoc:
      %w{@formats @fonts @worksheets}
    end
    ##
    # The Worksheet at _idx_, or - if _idx_ is a String -
    # the Worksheet with name == _idx_
    def worksheet idx
      case idx
      when Integer
        @worksheets[idx]
      when String
        @worksheets.find do |sheet| sheet.name == idx end
      end
    end
    ##
    # Write this Workbook to a File, IO Stream or Writer Object. The latter will
    # make more sense once there are more than just an Excel-Writer available.
    def write io_path_or_writer
      if io_path_or_writer.is_a? Writer
        io_path_or_writer.write self
      else
        writer(io_path_or_writer).write(self)
      end
    end
    ##
    # Returns a new instance of the default Writer class for this Workbook (can
    # only be an Excel::Writer::Workbook at this time)
    def writer io_or_path, type=Excel, version=self.version
      if type == Excel
        Excel::Writer::Workbook.new io_or_path
      else
        raise NotImplementedError, "No Writer defined for #{type}"
      end
    end
  end
end
