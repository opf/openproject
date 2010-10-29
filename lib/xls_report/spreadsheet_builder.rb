require 'spreadsheet'

# A simple convenience class that wraps some of the spreadsheet
# gem's functionality. It's designed to build spreadsheets incrementally
# by adding row after row, but can be used for random access to the
# rows as well
#
# Multiple Worksheets are possible, the currently active worksheet and it's
# associated column widths are always accessible through the @sheet and @column_widths
# instance variables, the other worksheets are accessible through the #worksheet method.
# If a worksheet with an index larger than the number of worksheets is requested,
# a new worksheet is created.
#
class SpreadsheetBuilder

  Worksheet = Struct.new(:sheet, :column_widths)

  def initialize(name = nil)
    Spreadsheet.client_encoding = 'UTF-8'
    @xls = Spreadsheet::Workbook.new
    @worksheets = []
    worksheet(0, name)
  end

  # Retrieve or create the worksheet at index x
  def worksheet(idx, name = nil)
    name ||= "Worksheet #{@worksheets.length + 1}"
    if @worksheets[idx].nil?
      @worksheets[idx] = Worksheet.new.tap do |wb|
        wb.sheet = @xls.create_worksheet(:name => name)
        wb.column_widths = []
      end
    end

    @sheet = @worksheets[idx].sheet
    @column_widths = @worksheets[idx].column_widths
  end

  # Update column widths and wrap text if neccessary
  def update_sheet_widths
    @column_widths.count.times do |idx|
      if @column_widths[idx] > 60
        @sheet.column(idx).width = 60
        @sheet.rows.each do |row|
          fmt = row.formats[idx] || @sheet.column(idx).default_format
          fmt.text_wrap = true
          row.set_format(idx, fmt)
        end
      else
        @sheet.column(idx).width = @column_widths[idx]
      end
    end
  end

  # Get the approximate width of a value as seen in the excel sheet
  def get_value_width(value)
    if ['Time', 'Date'].include?(value.class.name)
      return 18 unless value.to_s.length < 18
    end

    tot_w = [Float(0)]
    idx=0
    value.to_s.each_char do |c|
      case c
      when '1', '.', ';', ':', ',', ' ', 'i', 'I', 'j', 'J', '(', ')', '[', ']', '!', '-', 't', 'l'
        tot_w[idx] += 0.6
      when 'W', 'M', 'D'
        tot_w[idx] += 1.2
      when "\n"
        idx = idx + 1
        tot_w << Float(0)
      else
        tot_w[idx] += 1.05
      end
    end

    wdth=0
    tot_w.each do |w|
      wdth = w unless w<wdth
    end

    return wdth+1.5
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
    title_format = Spreadsheet::Format.new(:weight => :bold, :size => 18)
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
  def add_headers(arr, idx = 1)
    header_format = Spreadsheet::Format.new(:weight => :bold)
    arr.size.times { |i| @sheet.row(idx).set_format(i, header_format) }
    idx = [idx, 1].max
    add_row(arr, idx)
  end

  # Add a simple row. This will default to the next row in the sequence.
  # Fixnums, Dates and Times are preserved, all other types are converted
  # to String as the spreadsheet gem cannot do more formats
  def add_row(arr, idx = nil)
    idx ||= [@sheet.last_row_index + 1, 1].max
    column_array = []
    arr.each_with_index do |c,i|
      value = if ['Time', 'Date', 'Fixnum', 'Float', 'Integer'].include?(c.class.name)
        c
      elsif c.class == BigDecimal
        c.to_f
      else
        c.to_s.gsub('_', ' ').gsub("\r\n", "\n").gsub("\r", "\n")
      end
      column_array << value
      @column_widths[i] = 0 if @column_widths[i].nil?
      value_width = get_value_width(value)
      @column_widths[i] = value_width if @column_widths[i] < value_width
    end
    @sheet.row(idx).concat column_array
  end

  # Add a default format to the column at index
  def add_format_option_to_column(index, opt)
    unless opt.empty?
      fmt = @sheet.column(index).default_format
      opt.each do |k,v|
        fmt.send(:"#{k.to_sym}=", v) if fmt.respond_to? :"#{k.to_sym}="
      end
      @sheet.column(index).default_format = fmt
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
  def raw_xls
    @xls
  end

  def raw_sheet
    @sheet
  end
end
