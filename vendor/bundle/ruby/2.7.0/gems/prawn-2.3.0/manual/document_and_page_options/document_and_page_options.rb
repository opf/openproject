# frozen_string_literal: true

# Examples for stamps and repeaters.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename, page_size: 'FOLIO') do
  package 'document_and_page_options' do |p|
    p.example 'page_size',    eval_source: false, full_source: true
    p.example 'page_margins', eval_source: false, full_source: true
    p.example 'background',   eval_source: false, full_source: true
    p.example 'metadata',     eval_source: false, full_source: true
    p.example 'print_scaling', eval_source: false, full_source: true

    p.intro do
      prose <<-TEXT
        So far we've already seen how to create new documents and start new
        pages. This chapter expands on the previous examples by showing other
        options avialable. Some of the options are only available when creating
        new documents.

        The examples show:
      TEXT

      list(
        'How to configure page size',
        'How to configure page margins',
        'How to use a background image',
        'How to add metadata to the generated PDF'
      )
    end
  end
end
