# encoding: utf-8
#
# Another way to reduce the number of cells is to <code>filter</code> the table.
#
# <code>filter</code> is just like <code>Enumerable#select</code>. Pass it a
# block and it will iterate through the cells returning a new
# <code>Prawn::Table::Cells</code> instance containing only those cells for
# which the block was not false.
#
require File.expand_path(File.join(File.dirname(__FILE__),
                                   %w[.. example_helper]))

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  data = [ ["Item", "Jan Sales", "Feb Sales"],
           ["Oven", 17, 89],
           ["Fridge", 62, 30],
           ["Microwave", 71, 47]
         ]

  table(data) do
    values = cells.columns(1..-1).rows(1..-1)

    bad_sales = values.filter do |cell|
      cell.content.to_i < 40
    end

    bad_sales.background_color = "FFAAAA"

    good_sales = values.filter do |cell|
      cell.content.to_i > 70
    end

    good_sales.background_color = "AAFFAA"
  end
end
