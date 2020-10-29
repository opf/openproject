# frozen_string_literal: true

# The <code>repeat</code> method is quite versatile when it comes to define
# the intervals at which the content block should repeat.
#
# The interval may be a symbol (<code>:all</code>, <code>:odd</code>,
# <code>:even</code>), an array listing the pages, a range or a
# <code>Proc</code> that receives the page number as an argument and should
# return true if the content is to be repeated on the given page.
#
# You may also pass an option <code>:dynamic</code> to reevaluate the code block
# on every call which is useful when the content changes based on the page
# number.
#
# It is also important to say that no matter where you define the repeater it
# will be applied to all matching pages.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  repeat(:all) do
    draw_text 'All pages', at: bounds.top_left
  end

  repeat(:odd) do
    draw_text 'Only odd pages', at: [0, 0]
  end

  repeat(:even) do
    draw_text 'Only even pages', at: [0, 0]
  end

  repeat([1, 3, 7]) do
    draw_text 'Only on pages 1, 3 and 7', at: [100, 0]
  end

  repeat(2..4) do
    draw_text 'From the 2nd to the 4th page', at: [300, 0]
  end

  repeat(->(pg) { (pg % 3).zero? }) do
    draw_text 'Every third page', at: [250, 20]
  end

  repeat(:all, dynamic: true) do
    draw_text page_number, at: [500, 0]
  end

  10.times do
    start_new_page
    draw_text 'A wonderful page', at: [400, 400]
  end
end
