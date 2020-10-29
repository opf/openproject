# frozen_string_literal: true

# Examples for using grid layouts.

require_relative '../example_helper'

Prawn::ManualBuilder::Example.generate('layout.pdf', page_size: 'FOLIO') do
  package 'layout' do |p|
    p.example 'simple_grid'
    p.example 'boxes'
    p.example 'content'

    p.intro do
      prose <<-TEXT
        Prawn has support for two-dimensional grid based layouts out of the box.

        The examples show:
      TEXT

      list(
        'How to define the document grid',
        'How to configure the grid rows and columns gutters',
        'How to create boxes according to the grid'
      )
    end
  end
end
