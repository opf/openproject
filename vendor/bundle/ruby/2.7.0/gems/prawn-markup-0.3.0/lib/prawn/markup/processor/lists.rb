# frozen_string_literal: true

module Prawn
  module Markup
    module Processor::Lists
      def self.prepended(base)
        base.known_elements.push('ol', 'ul', 'li')
      end

      def start_ol
        start_list(true)
      end

      def start_ul
        start_list(false)
      end

      def start_list(ordered)
        if current_list
          add_cell_text_node(current_list_item)
        elsif current_table
          add_cell_text_node(current_cell)
        else
          add_current_text
        end
        @list_stack.push(Elements::List.new(ordered))
      end

      def end_list
        list = list_stack.pop
        append_list(list) unless list.items.empty?
      end
      alias end_ol end_list
      alias end_ul end_list

      def start_li
        return unless inside_container?

        current_list.items << Elements::Item.new
      end

      def end_li
        return unless inside_container?

        add_cell_text_node(current_list_item)
      end

      def start_img
        if current_list
          add_cell_image(current_list_item)
        else
          super
        end
      end

      private

      attr_reader :list_stack

      def reset
        @list_stack = []
        super
      end

      def current_list
        list_stack.last
      end

      def current_list_item
        current_list.items.last
      end

      def inside_container?
        super || current_list
      end

      def append_list(list)
        if list_stack.empty?
          if current_table
            current_cell.nodes << list
          else
            add_list(list)
          end
        else
          current_list_item.nodes << list
        end
      end

      def add_list(list)
        pdf.move_up(additional_cell_padding_top)
        draw_list(list)
        put_bottom_margin(text_margin_bottom + additional_cell_padding_top)
      rescue Prawn::Errors::CannotFit => e
        append_text(list_too_large_placeholder(e))
      end

      def draw_list(list)
        Builders::ListBuilder.new(pdf, list, pdf.bounds.width, options).draw
      end

      def list_too_large_placeholder(error)
        placeholder_value(%i[list placeholder too_large], error) || '[list content too large]'
      end
    end
  end
end
