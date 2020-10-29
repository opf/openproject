# encoding: utf-8

require File.join(File.expand_path(File.dirname(__FILE__)), "..", "spec_helper")
require 'set'

describe "Prawn::Table::Cell::SpanDummy" do
  before(:each) do
    @pdf = Prawn::Document.new
    @table = @pdf.table([
        [{:content => "A1-2", :colspan => 2}, {:content => "A-B3", :rowspan => 2}],
        [{:content => "B1-2", :colspan => 2}]
    ], :row_colors => [nil, 'EFEFEF'])
    @colspan_master = @table.cells[0,0]
    @colspan_dummy = @colspan_master.dummy_cells.first
    @rowspan_master = @table.cells[0,2]
    @rowspan_dummy = @table.cells[1,2]
  end

  it "colspan dummy delegates background_color to the master cell" do
    @colspan_dummy.background_color.should == @colspan_master.background_color
  end

  it "rowspan dummy delegates background_color to the master cell" do
    @rowspan_dummy.background_color.should == @rowspan_master.background_color
  end
end
