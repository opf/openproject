# frozen_string_literal: true

# The document outline tree is the set of links used to navigate through the
# various document sections and pages.
#
# To define the document outline we first use the <code>outline</code>
# method to lazily instantiate an outline object. Then we use the
# <code>define</code> method with a block to start the outline tree.
#
# The basic methods for creating outline nodes are <code>section</code> and
# <code>page</code>. The only difference between the two is that
# <code>page</code> doesn't accept a block and will only create leaf nodes
# while <code>section</code> accepts a block to create nested nodes.
#
# <code>section</code> accepts the title of the section and two options:
# <code>:destination</code> - a page number to link and <code>:closed</code> -
# a boolean value that defines if the nested outline nodes are shown when the
# document is open (defaults to true).
#
# <code>page</code> is very similar to section. It requires a
# <code>:title</code> option to be set and accepts a <code>:destination</code>.
#
# <code>section</code> and <code>page</code> may also be used without the
# <code>define</code> method but they will need to instantiate the
# <code>outline</code> object every time.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  # First we create 10 pages just to have something to link to
  (1..10).each do |index|
    text "Page #{index}"
    start_new_page
  end

  outline.define do
    section('Section 1', destination: 1) do
      page title: 'Page 2', destination: 2
      page title: 'Page 3', destination: 3
    end

    section('Section 2', destination: 4) do
      page title: 'Page 5', destination: 5

      section('Subsection 2.1', destination: 6, closed: true) do
        page title: 'Page 7', destination: 7
      end
    end
  end

  # Outside of the define block
  outline.section('Section 3', destination: 8) do
    outline.page title: 'Page 9', destination: 9
  end

  outline.page title: 'Page 10', destination: 10

  # Section and Pages without links. While a section without a link may be
  # useful to group some pages, a page without a link is useless
  outline.update do # update is an alias to define
    section('Section without link') do
      page title: 'Page without link'
    end
  end
end
