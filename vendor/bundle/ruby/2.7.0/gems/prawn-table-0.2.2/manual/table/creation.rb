# encoding: utf-8
#
# Creating tables with Prawn is fairly easy. There are two methods that will
# create tables for us <code>table</code> and <code>make_table</code>.
#
# Both are wrappers that create a new <code>Prawn::Table</code> object. The
# difference is that <code>table</code> calls the <code>draw</code> method
# after creating the table and <code>make_table</code> only returns the created
# table, so you have to call the <code>draw</code> method yourself.
#
# The most simple table can be created by providing only an array of arrays
# containing your data where each inner array represents one row.
#
require File.expand_path(File.join(File.dirname(__FILE__),
                                   %w[.. example_helper]))

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  t = make_table([ ["this is the first row"],
                   ["this is the second row"] ])
  t.draw
  move_down 20

  table([ ["short", "short", "loooooooooooooooooooong"],
          ["short", "loooooooooooooooooooong", "short"],
          ["loooooooooooooooooooong", "short", "short"] ])
end
