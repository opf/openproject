# frozen_string_literal: true

# The <code>column_box</code> method allows you to define columns that flow
# their contents from one section to the next. You can have a number of columns
# on the page, and only when the last column overflows will a new page be
# created.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  text 'The Prince',          align: :center, size: 18
  text 'Niccolò Machiavelli', align: :center, size: 14
  move_down 12

  column_box([0, cursor], columns: 2, width: bounds.width) do
    text((<<-TEXT.gsub(/\s+/, ' ') + "\n\n") * 3)
      All the States and Governments by which men are or ever have been ruled,
      have been and are either Republics or Princedoms. Princedoms are either
      hereditary, in which the sovereignty is derived through an ancient line
      of ancestors, or they are new. New Princedoms are either wholly new, as
      that of Milan to Francesco Sforza; or they are like limbs joined on to
      the hereditary possessions of the Prince who acquires them, as the
      Kingdom of Naples to the dominions of the King of Spain. The States thus
      acquired have either been used to live under a Prince or have been free;
      and he who acquires them does so either by his own arms or by the arms of
      others, and either by good fortune or by merit.
    TEXT
  end
end
