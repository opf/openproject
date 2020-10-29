# frozen_string_literal: true

require_relative 'example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')

Prawn::ManualBuilder::Example.generate(filename) do
  header('Prawn::Table')

  prose <<-END_TEXT
    As of Prawn 1.2.0, Prawn::Table has been extracted into its own
    semi-officially supported gem.

    Please see https://github.com/prawnpdf/prawn-table for more details.
  END_TEXT
end
