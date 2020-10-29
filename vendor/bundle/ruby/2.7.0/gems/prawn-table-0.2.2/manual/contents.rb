# encoding: utf-8
#
# Generates the Prawn by example manual.

require_relative "example_helper"

Encoding.default_external = Encoding::UTF_8

Prawn::ManualBuilder::Example.generate("manual.pdf",
  :skip_page_creation => true, :page_size => "FOLIO") do

  load_package "table"
end
