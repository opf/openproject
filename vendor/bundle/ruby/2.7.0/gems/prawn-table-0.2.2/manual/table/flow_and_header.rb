# encoding: utf-8
#
# If the table cannot fit on the current page it will flow to the next page just
# like free flowing text. If you would like to have the first row treated as a
# header which will be repeated on subsequent pages set the <code>:header</code>
# option to true.
#
require File.expand_path(File.join(File.dirname(__FILE__),
                                   %w[.. example_helper]))

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  data = [["This row should be repeated on every new page"]]
  data += [["..."]] * 30

  table(data, :header => true)
end
