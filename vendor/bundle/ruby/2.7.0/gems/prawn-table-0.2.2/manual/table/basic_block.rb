# encoding: utf-8
#
# All of the previous styling options we've seen deal with all the table cells
# at once.
#
# With initializer blocks we may deal with specific cells.
# A block passed to one of the table methods (<code>Prawn::Table.new</code>,
# <code>Prawn::Document#table</code>, <code>Prawn::Document#make_table</code>)
# will be called after cell setup but before layout. This is a very flexible way
# to specify styling and layout constraints.
#
# Just like the <code>Prawn::Document.generate</code> method, the table
# initializer blocks may be used with and without a block argument.
#
# The table class has three methods that are handy within an initializer block:
# <code>cells</code>, <code>rows</code> and <code>columns</code>. All three
# return an instance of <code>Prawn::Table::Cells</code> which represents
# a selection of cells.
#
# <code>cells</code> return all the table cells, while <code>rows</code> and
# <code>columns</code> accept a number or a range as argument which returns a
# single row/column or a range of rows/columns respectively. (<code>rows</code>
# and <code>columns</code> are also aliased as <code>row</code> and
# <code>column</code>)
#
# The <code>Prawn::Table::Cells</code> class also defines <code>rows</code> and
# <code>columns</code> so they may be chained to narrow the selection of cells.
#
# All of the cell styling options we've seen on previous examples may be set as
# properties of the selection of cells.
#
require File.expand_path(File.join(File.dirname(__FILE__),
                                   %w[.. example_helper]))

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  data = [ ["Header",           "A " * 5, "B"],
           ["Data row",         "C",      "D " * 5],
           ["Another data row", "E",      "F"]]

  table(data) do
    cells.padding = 12
    cells.borders = []

    row(0).borders      = [:bottom]
    row(0).border_width = 2
    row(0).font_style   = :bold

    columns(0..1).borders = [:right]

    row(0).columns(0..1).borders = [:bottom, :right]
  end
end
