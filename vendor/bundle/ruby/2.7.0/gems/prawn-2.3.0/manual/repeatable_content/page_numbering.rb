# frozen_string_literal: true

# The <code>number_pages</code> method is a simple way to number the pages of
# your document. It should be called towards the end of the document since
# pages created after the call won't be numbered.
#
# It accepts a string and a hash of options:
#
# <code>start_count_at</code> is the value from which to start numbering pages
#
# <code>total_pages</code> If provided, will replace <code>total</code> with
# the value given.  Useful for overriding the total number of pages when using
# the start_count_at option.
#
# <code>page_filter</code>, which is one of: <code>:all</code>,
# <code>:odd</code>, <code>:even</code>, an array, a range, or a Proc that
# receives the page number as an argument and should return true if the page
# number should be printed on that page.
#
# <code>color</code> which accepts the same values as <code>fill_color</code>
#
# As well as any option accepted by <code>text_box</code>

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  text 'This is the first page!'

  10.times do
    start_new_page
    text 'Here comes yet another page.'
  end

  string = 'page <page> of <total>'
  # Green page numbers 1 to 7
  options = {
    at: [bounds.right - 150, 0],
    width: 150,
    align: :right,
    page_filter: (1..7),
    start_count_at: 1,
    color: '007700'
  }
  number_pages string, options

  # Gray page numbers from 8 on up
  options[:page_filter] = ->(pg) { pg > 7 }
  options[:start_count_at] = 8
  options[:color] = '333333'
  number_pages string, options

  start_new_page
  text "See. This page isn't numbered and doesn't count towards the total."
end
