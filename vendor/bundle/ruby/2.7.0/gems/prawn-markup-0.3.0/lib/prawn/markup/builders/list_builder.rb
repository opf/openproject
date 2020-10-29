# frozen_string_literal: true

module Prawn
  module Markup
    module Builders
      class ListBuilder < NestableBuilder
        BULLET_CHAR = '•'
        BULLET_MARGIN = 10
        CONTENT_MARGIN = 10
        VERTICAL_MARGIN = 5

        def initialize(pdf, list, total_width, options = {})
          super(pdf, total_width, options)
          @list = list
          @column_widths = compute_column_widths
        end

        def make(main = false)
          pdf.make_table(convert_list, list_table_options) do |t|
            t.columns(0).style(column_cell_style(:bullet))
            t.columns(1).style(column_cell_style(:content))
            set_paddings(t, main)
          end
        end

        def draw
          # fix https://github.com/prawnpdf/prawn-table/issues/120
          pdf.font_size(column_cell_style(:content)[:size] || pdf.font_size) do
            make(true).draw
          end
        end

        private

        attr_reader :list, :column_widths

        def list_table_options
          {
            column_widths: column_widths,
            cell_style: { border_width: 0, inline_format: true }
          }
        end

        def set_paddings(table, main)
          set_row_padding(table, [0, 0, padding_bottom])
          if main
            set_row_padding(table.rows(0), [vertical_margin, 0, padding_bottom])
            set_row_padding(table.rows(-1), [0, 0, padding_bottom + vertical_margin])
          else
            set_row_padding(table.rows(-1), [0, 0, 0])
          end
        end

        def set_row_padding(row, padding)
          row.columns(0).padding = [*padding, bullet_margin]
          row.columns(1).padding = [*padding, content_margin]
        end

        def convert_list
          list.items.map.with_index do |item, i|
            if item.single?
              [bullet(i + 1), normalize_list_item_node(item.nodes.first)]
            else
              [bullet(i + 1), list_item_table(item)]
            end
          end
        end

        def list_item_table(item)
          data = item.nodes.map { |n| [normalize_list_item_node(n)] }
          style = column_cell_style(:content)
                  .merge(borders: [], padding: [0, 0, padding_bottom, 0])
          pdf.make_table(data, cell_style: style, column_widths: [content_width]) do
            rows(-1).padding = [0, 0, 0, 0]
          end
        end

        def normalize_list_item_node(node)
          normalizer = "item_node_for_#{type_key(node)}"
          if respond_to?(normalizer, true)
            send(normalizer, node)
          else
            ''
          end
        end

        def item_node_for_list(node)
          # sublist
          ListBuilder.new(pdf, node, content_width, options).make
        end

        def item_node_for_hash(node)
          normalize_cell_hash(node, content_width)
        end

        def item_node_for_string(node)
          node
        end

        def content_width
          column_widths.last && column_widths.last - content_margin
        end

        def compute_column_widths
          return [] if list.items.empty?

          bullet_width = bullet_text_width + bullet_margin
          text_width = total_width && (total_width - bullet_width)
          [bullet_width, text_width]
        end

        def bullet_text_width
          font = bullet_font
          font_size = column_cell_style(:bullet)[:size] || pdf.font_size
          encoded = font.normalize_encoding(bullet(list.items.size))
          font.compute_width_of(encoded, size: font_size)
        end

        def bullet_font
          style = column_cell_style(:bullet)
          font_name = style[:font] || pdf.font.family
          pdf.find_font(font_name, style: style[:font_style])
        end

        # option accessors

        def bullet(index)
          list.ordered ? "#{index}." : (column_cell_style(:bullet)[:char] || BULLET_CHAR)
        end

        # margin before bullet
        def bullet_margin
          column_cell_style(:bullet)[:margin] || BULLET_MARGIN
        end

        # margin between bullet and content
        def content_margin
          column_cell_style(:content)[:margin] || CONTENT_MARGIN
        end

        # margin at the top and the bottom of the list
        def vertical_margin
          list_options[:vertical_margin] || VERTICAL_MARGIN
        end

        # vertical padding between list items
        def padding_bottom
          column_cell_style(:content)[:leading] || 0
        end

        def column_cell_style(key)
          @column_cell_styles ||= {}
          @column_cell_styles[key] ||=
            extract_text_cell_style(options[:text] || {}).merge(list_options[key])
        end

        def list_options
          @list_options ||= HashMerger.deep(default_list_options, options[:list] || {})
        end

        def default_list_options
          {
            content: {},
            bullet: { align: :right }
          }
        end
      end
    end
  end
end
