# encoding: utf-8
#
# Examples for tables.
#
require File.expand_path(File.join(File.dirname(__FILE__),
                                   %w[.. example_helper]))

Prawn::ManualBuilder::Example.generate("table.pdf", :page_size => "FOLIO") do
  package "table" do |p|
    p.name = "Prawn::Table"

    p.section "Basics" do |s|
      s.example "creation"
      s.example "content_and_subtables"
      s.example "flow_and_header"
      s.example "position"
    end

    p.section "Styling" do |s|
      s.example "column_widths"
      s.example "width"
      s.example "row_colors"
      s.example "cell_dimensions"
      s.example "cell_borders_and_bg"
      s.example "cell_border_lines"
      s.example "cell_text"
      s.example "image_cells"
      s.example "span"
      s.example "before_rendering_page"
    end

    p.section "Initializer Block" do |s|
      s.example "basic_block"
      s.example "filtering"
      s.example "style"
    end

    p.intro do
      prose("Prawn comes with table support out of the box. Tables can be styled in whatever way you see fit. The whole table, rows, columns and cells can be styled independently from each other.

      The examples show:")

      list( "How to create tables",
            "What content can be placed on tables",
            "Subtables (or tables within tables)",
            "How to style the whole table",
            "How to use initializer blocks to style only specific portions of the table"
          )
    end

  end
end
