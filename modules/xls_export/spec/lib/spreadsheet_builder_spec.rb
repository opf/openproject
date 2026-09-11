require "spec_helper"

RSpec.describe "SpreadsheetBuilder" do
  before do
    @spreadsheet = OpenProject::XlsExport::SpreadsheetBuilder.new
    @sheet = @spreadsheet.send(:raw_sheet)
  end

  it "adds a single title in the first row" do
    @spreadsheet.add_title("A fancy title")
    expect(@sheet.last_row_index).to eq(0)
  end

  it "adds the title completely in the first cell" do
    title = "A fancy title"
    @spreadsheet.add_title(title)
    expect(@sheet.last_row[0]).to eq(title)
    expect(@sheet.last_row[1]).to be_nil
  end

  it "overwrites titles in consecutive calls" do
    title = "A fancy title"
    @spreadsheet.add_title(title)
    @spreadsheet.add_title(title)
    expect(@sheet.last_row_index).to eq(0)
  end

  it "does some formatting on the title" do
    @spreadsheet.add_title("A fancy title")
    expect(@sheet.last_row.format(0)).not_to eq(@sheet.last_row.format(1))
  end

  it "adds empty rows starting in the second line" do
    @spreadsheet.add_empty_row
    expect(@sheet.last_row_index).to eq(1)
  end

  it "adds empty rows at the next sequential row" do
    @spreadsheet.add_empty_row
    first = @sheet.last_row_index
    @spreadsheet.add_empty_row
    expect(@sheet.last_row_index).to eq(first + 1)
  end

  it "adds headers in the second line per default" do
    @spreadsheet.add_headers((1..3).to_a)
    expect(@sheet.last_row_index).to eq(1)
  end

  it "allows adding headers in the first line" do
    @spreadsheet.add_headers((1..3).to_a, 0)
    expect(@sheet.last_row_index).to eq(0)
  end

  it "adds headers with some formatting" do
    @spreadsheet.add_headers([1], 0)
    expect(@sheet.last_row.format(0)).not_to eq(@sheet.last_row.format(2))
  end

  it "starts adding rows in the first line" do
    @spreadsheet.add_row((1..3).to_a)
    expect(@sheet.last_row_index).to eq(1)
  end

  it "adds rows sequentially" do
    @spreadsheet.add_row((1..3).to_a)
    first = @sheet.last_row_index
    @spreadsheet.add_row((1..3).to_a)
    expect(@sheet.last_row_index).to eq(first + 1)
  end

  it "applies no formatting on rows" do
    @spreadsheet.add_row([1])
    expect(@sheet.last_row.format(0)).to eq(@sheet.last_row.format(1))
  end

  describe "column width of a date column" do
    def width_for(number_format)
      builder = OpenProject::XlsExport::SpreadsheetBuilder.new
      builder.add_headers([""], 0) # as every exporter does, #add_row skips row 0
      builder.add_row([Date.new(2026, 8, 24)])
      builder.add_format_option_to_column(0, number_format:)
      builder.xls

      builder.send(:raw_sheet).column(0).width
    end

    it "widens the column so that a long date format still fits" do
      expect(width_for("MMMM DD, YYYY")).to be > width_for("YYYY-MM-DD")
    end

    it "leaves number formats to the plain value width" do
      expect(width_for("0.00")).to eq(width_for("YYYY-MM-DD"))
    end
  end

  it "keeps booleans as booleans" do
    builder = OpenProject::XlsExport::SpreadsheetBuilder.new
    builder.add_row([true, false])

    expect(builder.send(:raw_sheet).last_row.to_a).to eq([true, false])
  end

  it "alwayses use unix newlines" do
    @spreadsheet.add_row(["Some text including a windows newline (\r\n)", "And an old-style mac os newline (\r)"])
    2.times do |i|
      expect(@spreadsheet.send(:raw_sheet).last_row[i]).not_to include("\r")
      expect(@spreadsheet.send(:raw_sheet).last_row[i]).not_to include("\r\n")
      expect(@spreadsheet.send(:raw_sheet).last_row[i]).to include("\n")
    end
  end
end
