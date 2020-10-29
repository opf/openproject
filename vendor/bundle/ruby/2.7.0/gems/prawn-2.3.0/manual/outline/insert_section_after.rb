# frozen_string_literal: true

# Another way to insert nodes into an existing outline is the
# <code>insert_section_after</code> method.
#
# It accepts the title of the node that the new section will go after and a
# block declaring the new section.
#
# As is the case with <code>add_subsection_to</code> the section added
# doesn't need to be a section, it may be just a page.

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
  outline.insert_section_after('Page 2') do
    outline.section('Section after Page 2') do
      outline.page title: 'Page 4', destination: 4
    end
  end

  outline.insert_section_after('Section 1') do
    outline.section('Section after Section 1') do
      outline.page title: 'Page 5', destination: 5
    end
  end

  # Adding just a page
  outline.insert_section_after('Page 3') do
    outline.page title: 'Page after Page 3', destination: 6
  end
end
