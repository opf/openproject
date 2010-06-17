require 'spec_helper'
require 'xls_report/spreadsheet_builder'

describe "SpreadsheetBuilder" do
  before(:each) do
    @spreadsheet = SpreadsheetBuilder.new
    @sheet = @spreadsheet.send(:raw_sheet)
  end
  
  it "should add a single title in the first row" do
    @spreadsheet.add_title("A fancy title")
    @sheet.last_row_index.should == 0
  end

  it "should add the title complety in the first cell" do
    title = "A fancy title"
    @spreadsheet.add_title(title)
    @sheet.last_row[0].should == title
    @sheet.last_row[1].should == nil
  end

  it "should overwrite titles in consecutive calls" do
    title = "A fancy title"
    @spreadsheet.add_title(title)
    @spreadsheet.add_title(title)
    @sheet.last_row_index.should == 0
  end
  
  it "should do some formatting on the title" do
    @spreadsheet.add_title("A fancy title")
    @sheet.last_row.format(0).should_not == @sheet.last_row.format(1)
  end
  
  it "should add empty rows starting in the second line" do
    @spreadsheet.add_empty_row
    @sheet.last_row_index.should == 1
  end
  
  it "should add empty rows at the next sequential row" do
    @spreadsheet.add_empty_row
    first = @sheet.last_row_index
    @spreadsheet.add_empty_row
    @sheet.last_row_index.should == (first + 1)
  end
  
  it "should add headers in the second line per default" do
    @spreadsheet.add_headers((1..3).to_a)
    @sheet.last_row_index.should == 1
  end
  
  it "should allow adding headers in the first line" do
    @spreadsheet.add_headers((1..3).to_a, 0)
    @sheet.last_row_index.should == 0
  end
  
  it "should add headers with some formatting" do
    @spreadsheet.add_headers([1], 0)
    @sheet.last_row.format(0).should_not == @sheet.last_row.format(2)
  end
  
  it "should start adding rows in the first line" do
    @spreadsheet.add_row((1..3).to_a)
    @sheet.last_row_index.should == 1
  end
  
  it "should add rows sequentially" do
    @spreadsheet.add_row((1..3).to_a)
    first = @sheet.last_row_index
    @spreadsheet.add_row((1..3).to_a)
    @sheet.last_row_index.should == (first + 1)
  end
  
  it "should apply no formatting on rows" do
    @spreadsheet.add_row([1])
    @sheet.last_row.format(0).should == @sheet.last_row.format(1)
  end
  
  it "should always use unix newlines" do
    @spreadsheet.add_row(["Some text including a windows newline (\r\n)", "And an old-style mac os newline (\r)"])
    2.times do |i|
      @spreadsheet.send("raw_sheet").last_row[i].should_not include("\r")
      @spreadsheet.send("raw_sheet").last_row[i].should_not include("\r\n")
      @spreadsheet.send("raw_sheet").last_row[i].should include("\n")
    end
  end
end