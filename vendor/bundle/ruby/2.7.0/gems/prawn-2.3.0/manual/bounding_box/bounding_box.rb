# frozen_string_literal: true

# Examples for bounding boxes.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename, page_size: 'FOLIO') do
  package 'bounding_box' do |p|
    p.section 'Basics' do |s|
      s.example 'creation'
      s.example 'bounds'
    end

    p.section 'Advanced' do |s|
      s.example 'stretchy'
      s.example 'nesting'
      s.example 'indentation'
      s.example 'canvas'
      s.example 'russian_boxes'
    end

    p.intro do
      prose <<-TEXT
        Bounding boxes are the basic containers for structuring the content
        flow. Even being low level building blocks sometimes their simplicity is
        very welcome.

        The examples show:
      TEXT

      list(
        'How to create bounding boxes with specific dimensions',
        'How to inspect the current bounding box for its coordinates',
        'Stretchy bounding boxes',
        'Nested bounding boxes',
        'Indent blocks'
      )
    end
  end
end
