# frozen_string_literal: true

# Examples for Prawn basic concepts.
#

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename, page_size: 'FOLIO') do
  package 'basic_concepts' do |p|
    p.example 'creation', eval_source: false, full_source: true
    p.example 'origin'
    p.example 'cursor'
    p.example 'other_cursor_helpers'
    p.example 'adding_pages'
    p.example 'measurement'
    p.example 'view', eval_source: false, full_source: true

    p.intro do
      prose <<-TEXT
        This chapter covers the minimum amount of functionality you'll need to
        start using Prawn.

        If you are new to Prawn this is the first chapter to read. Once you are
        comfortable with the concepts shown here you might want to check the
        Basics section of the Graphics, Bounding Box and Text sections.

        The examples show:
      TEXT

      list(
        'How to create new pdf documents in every possible way',
        'Where the origin for the document coordinates is. What are Bounding '\
          'Boxes and how they interact with the origin',
        'How the cursor behaves',
        'How to start new pages',
        'What the base unit for measurement and coordinates is and how to use '\
          'other convenient measures',
        "How to build custom view objects that use Prawn's DSL"
      )
    end
  end
end
