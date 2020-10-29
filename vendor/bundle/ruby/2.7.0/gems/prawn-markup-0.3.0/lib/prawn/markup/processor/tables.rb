# frozen_string_literal: true

module Prawn
  module Markup
    module Processor::Tables
      def self.prepended(base)
        base.known_elements.push('table', 'tr', 'td', 'th')
      end

      def start_table
        if current_table
          add_cell_text_node(current_cell)
        else
          add_current_text
        end
        table_stack.push([])
      end

      def end_table
        data = table_stack.pop
        return if data.empty? || data.all?(&:empty?)

        if table_stack.empty?
          add_table(data)
        else
          current_cell.nodes << data
        end
      end

      def start_tr
        return unless current_table

        current_table << []
      end

      def start_td
        return unless current_table

        current_table.last << Elements::Cell.new(width: style_properties['width'])
      end

      def start_th
        return unless current_table

        current_table.last << Elements::Cell.new(width: style_properties['width'], header: true)
      end

      def end_td
        if current_table
          add_cell_text_node(current_cell)
        else
          add_current_text
        end
      end
      alias end_th end_td

      def start_img
        if current_table
          add_cell_image(current_cell)
        else
          super
        end
      end

      private

      attr_reader :table_stack

      def reset
        @table_stack = []
        super
      end

      def current_table
        table_stack.last
      end

      def current_cell
        current_table.last.last
      end

      def inside_container?
        super || current_table
      end

      def add_cell_text_node(cell, options = {})
        return unless buffered_text?

        cell.nodes << options.merge(content: dump_text.strip)
      end

      def add_cell_image(cell)
        add_cell_text_node(cell)
        img = image_properties(current_attrs['src'])
        cell.nodes << img || invalid_image_placeholder
      end

      def add_table(cells)
        draw_table(cells)
        put_bottom_margin(text_margin_bottom + additional_cell_padding_top + text_leading)
      rescue Prawn::Errors::CannotFit => e
        append_text(table_too_large_placeholder(e))
      end

      def draw_table(cells)
        Builders::TableBuilder.new(pdf, cells, pdf.bounds.width, options).draw
      end

      def table_too_large_placeholder(error)
        placeholder_value(%i[table placeholder too_large], error) || '[table content too large]'
      end

      def additional_cell_padding_top
        # as used in Prawn::Table::Cell::Text#draw_content move_down
        (text_line_gap + text_descender) / 2
      end
    end
  end
end
