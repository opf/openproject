# encoding: utf-8
#
# Table cells can span multiple columns, rows, or both. When building a cell,
# use the hash argument constructor with a <code>:colspan</code> and/or
# <code>:rowspan</code> argument. Row or column spanning must be specified when
# building the data array; you can't set the span in the table's initialization
# block. This is because cells are laid out in the grid before that block is
# called, so that references to row and column numbers make sense.
#
# Cells are laid out in the order given, skipping any positions spanned by
# previously instantiated cells. Therefore, a cell with <code>rowspan: 2</code>
# will be missing at least one cell in the row below it. See the code and table
# below for an example.
#
# It is illegal to overlap cells via spanning. A
# <code>Prawn::Errors::InvalidTableSpan</code> error will be raised if spans
# would cause cells to overlap.
#
require File.expand_path(File.join(File.dirname(__FILE__),
                                   %w[.. example_helper]))

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  table([
    ["A", {:content => "2x1", :colspan => 2}, "B"],
    [{:content => "1x2", :rowspan => 2}, "C", "D", "E"],
    [{:content => "2x2", :colspan => 2, :rowspan => 2}, "F"],
    ["G", "H"]
  ])
end
