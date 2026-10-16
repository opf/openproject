require "spreadsheet"

# A simple convenience class that wraps some of the spreadsheet
# gem's functionality. It's designed to build spreadsheets incrementally
# by adding row after row, but can be used for random access to the
# rows as well
#
# Multiple Worksheets are possible, the currently active worksheet and its
# associated column widths are always accessible through the @sheet and @column_widths
# instance variables, the other worksheets are accessible through the #worksheet method.
# If a worksheet with an index larger than the number of worksheets is requested,
# a new worksheet is created.
#

module OpenProject::XlsExport
  class SpreadsheetBuilder
    Worksheet = Struct.new(:sheet, :column_widths) unless defined? Worksheet

    def initialize(name = nil)
      Spreadsheet.client_encoding = "UTF-8"
      @xls = Spreadsheet::Workbook.new
      @worksheets = []
      worksheet(0, name)
    end

    # Retrieve or create the worksheet at index x
    def worksheet(idx, name = nil)
      @worksheets[idx] ||= create_worksheet(name)

      @sheet = @worksheets[idx].sheet
      @column_widths = @worksheets[idx].column_widths
    end

    def create_worksheet(name)
      name ||= "Worksheet #{@worksheets.length + 1}"
      Worksheet.new.tap do |wb|
        wb.sheet = @xls.create_worksheet(name: escaped_worksheet_name(name))
        wb.sheet.default_format.vertical_align = :top
        wb.column_widths = []
      end
    end

    # Update column widths and wrap text if necessary
    def update_sheet_widths
      @column_widths.count.times do |idx|
        if @column_widths[idx] > 60
          limit_and_wrap_column(idx, 60)
        else
          @sheet.column(idx).width = column_width_including_affix(idx)
        end
      end
    end

    # Get the approximate width of a value as seen in the excel sheet
    def get_value_width(value)
      return 18 if (value.is_a?(Time) || value.is_a?(Date)) && value.to_s.length >= 18

      value.to_s.split("\n").map { |line| line_width(line) }.max.to_f + 1.5
    end

    # Add a "Title". This basically just set the first column to
    # the passed text and makes it bold and larger (font-size 18)
    def add_title(arr_or_str)
      if arr_or_str.respond_to? :to_str
        @sheet[0, 0] = arr_or_str
      else
        @sheet.row(0).concat arr_or_str
        value_width = get_value_width(arr_or_str[0] * 2)
        @column_widths[0] = value_width if (@column_widths[0] || 0) < value_width
      end
      title_format = Spreadsheet::Format.new(weight: :bold, size: 18)
      @sheet.row(0).set_format(0, title_format)
    end

    # Add an empty row in the next sequential position. Convenience method
    # for calling add_row([""])
    def add_empty_row
      add_row([""])
    end

    # Add headers. This is usually used for adding a table header to the
    # second row in the document, but the row can be set using the second
    # optional parameter. The format is automatically set to bold font
    def add_headers(arr, idx = nil)
      header_format = Spreadsheet::Format.new(weight: :bold)
      add_row(arr, idx)
      idx ||= @sheet.last_row_index
      (arr.size + 1).times { |i| @sheet.row(idx).set_format(i, header_format) }
    end

    # Add sums. The format, that might already have been set (e.g. currency formatting)
    # is not overwritten but extended.
    def add_sums(arr, idx = nil)
      add_row(arr, idx)
      idx ||= @sheet.last_row_index
      (arr.size + 1).times do |i|
        fmt = @sheet.column(i).default_format.clone
        fmt.font = fmt.font.clone
        fmt.update_format(weight: :bold)
        @sheet.row(idx).set_format(i, fmt)
      end
    end

    def increase_column_width(index, amount)
      @sheet.column(index).width += amount
    end

    # Add a simple row. This will default to the next row in the sequence.
    # Numeric, Date, Time and boolean instances are preserved so that they are
    # written as native cells and the cell formats set on the columns apply,
    # all other types are converted to String as the spreadsheet gem cannot do
    # more formats
    def add_row(arr, idx = nil)
      idx ||= [@sheet.last_row_index + 1, 1].max
      values = arr.map { |cell| cell_value(cell) }
      values.each_with_index { |value, i| track_column_width(i, value) }
      @sheet.row(idx).concat values
    end

    # Add a default format to the column at index
    def add_format_option_to_column(index, opt)
      unless opt.empty?
        fmt = @sheet.column(index).default_format.clone
        opt.each do |k, v|
          fmt.send(:"#{k.to_sym}=", v) if fmt.respond_to? :"#{k.to_sym}="
        end
        @sheet.column(index).default_format = fmt
        widen_for_date_format(index, opt[:number_format])
      end
    end

    # Return the next free row we would write to in natural indexing (Starting at 1)
    def current_row
      @sheet.row_count
    end

    # Return the xls file as a string
    def xls
      @worksheets.length.times do |i|
        worksheet(i)
        update_sheet_widths
      end
      io = StringIO.new
      @xls.write(io)
      io.rewind
      io.read
    end

    private

    def line_width(line)
      line.each_char.sum { |char| char_width(char) }
    end

    def char_width(char)
      case char
      when "0".."9", "W", "M", "D" then 1.2
      when ".", ";", ":", ",", " ", "i", "I", "j", "J", "(", ")", "[", "]", "!", "-", "t", "l" then 0.7
      else 1.05
      end
    end

    def cell_value(cell)
      case cell
      when BigDecimal then cell.to_f
      when Date, Time, Numeric, true, false then cell
      else cell.to_s.gsub("\r\n", "\n").tr("\r", "\n")
      end
    end

    def track_column_width(index, value)
      @column_widths[index] ||= 0
      width = get_value_width(value)
      @column_widths[index] = width if @column_widths[index] < width
    end

    # The values of a date column are written as Date or Time and their width is
    # measured as such, but excel renders them through the column's number format,
    # which may well be wider - a column too narrow for its own format renders as
    # "########".
    def widen_for_date_format(index, number_format)
      return unless Spreadsheet::Format.new(number_format:).date_or_time?

      width = get_value_width(number_format.delete('"'))
      @column_widths[index] = width if width > @column_widths[index].to_f
    end

    def column_width_including_affix(index)
      contains_currency = @sheet.rows.any? do |row|
        fmt = row.formats[index] || @sheet.column(index).default_format
        fmt.number_format.include?(currency_sign)
      end

      width = @column_widths[index]

      if contains_currency
        width += currency_sign.length + 2
      end

      width
    end

    def limit_and_wrap_column(index, limit)
      @sheet.column(index).width = limit
      @sheet.rows.each do |row|
        fmt = row.formats[index] || @sheet.column(index).default_format
        fmt.text_wrap = true
        row.set_format(index, fmt)
      end
    end

    def raw_xls
      @xls
    end

    def raw_sheet
      @sheet
    end

    def currency_sign
      Setting.costs_currency
    end

    def escaped_worksheet_name(name)
      name.gsub!(/[\/\\*\[\]:?]/, "#")
      name = name[0, [name.length, 27].min] + "..." if name.length > 31

      name
    end
  end
end
