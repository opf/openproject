# frozen_string_literal: true

# We have already seen how to define an outline tree sequentially.
#
# If you'd like to add nodes to the middle of an outline tree the
# <code>add_subsection_to</code> may help you.
#
# It allows you to insert sections to the outline tree at any point. Just
# provide the <code>title</code> of the parent section, the
# <code>position</code> you want the new subsection to be inserted
# <code>:first</code> or <code>:last</code> (defaults to <code>:last</code>)
# and a block to declare the subsection.
#
# The <code>add_subsection_to</code> block doesn't necessarily create new
# sections, it may also create new pages.
#
# If the parent title provided is the title of a page. The page will be
# converted into a section to receive the subsection created.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  # First we create 10 pages and some default outline
  (1..10).each do |index|
    text "Page #{index}"
    start_new_page
  end

  outline.define do
    section('Section 1', destination: 1) do
      page title: 'Page 2', destination: 2
      page title: 'Page 3', destination: 3
    end
  end

  # Now we will start adding nodes to the previous outline
  outline.add_subsection_to('Section 1', :first) do
    outline.section('Added later - first position') do
      outline.page title: 'Page 4', destination: 4
      outline.page title: 'Page 5', destination: 5
    end
  end

  outline.add_subsection_to('Section 1') do
    outline.page title: 'Added later - last position',
                 destination: 6
  end

  outline.add_subsection_to('Added later - first position') do
    outline.page title: 'Another page added later',
                 destination: 7
  end

  # The title provided is for a page which will be converted into a section
  outline.add_subsection_to('Page 3') do
    outline.page title: 'Last page added',
                 destination: 8
  end
end
