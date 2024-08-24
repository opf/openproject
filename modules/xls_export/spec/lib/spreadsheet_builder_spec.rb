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

  it "alwayses use unix newlines" do
    @spreadsheet.add_row(["Some text including a windows newline (\r\n)", "And an old-style mac os newline (\r)"])
    2.times do |i|
      expect(@spreadsheet.send(:raw_sheet).last_row[i]).not_to include("\r")
      expect(@spreadsheet.send(:raw_sheet).last_row[i]).not_to include("\r\n")
      expect(@spreadsheet.send(:raw_sheet).last_row[i]).to include("\n")
    end
  end
end
