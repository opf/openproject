# frozen_string_literal: true

module Prawn
  module Markup
    module Builders
      class TableBuilder < NestableBuilder
        FAILOVER_STRATEGIES = %i[equal_widths subtable_placeholders].freeze

        DEFAULT_CELL_PADDING = 5

        MIN_COL_WIDTH = 1.cm

        def initialize(pdf, cells, total_width, options = {})
          super(pdf, total_width, options)
          @cells = cells
          @column_widths = []
        end

        def make
          compute_column_widths
          pdf.make_table(convert_cells, prawn_table_options)
        end

        def draw
          # fix https://github.com/prawnpdf/prawn-table/issues/120
          pdf.font_size(table_options[:cell][:size] || pdf.font_size) do
            make.draw
          end
        rescue Prawn::Errors::CannotFit => e
          if failover_on_error
            draw
          else
            raise e
          end
        end

        private

        attr_reader :cells, :column_widths, :failover_strategy

        def prawn_table_options
          static_prawn_table_options.tap do |options|
            options[:width] = total_width
            options[:header] = cells.first && cells.first.all?(&:header)
            options[:column_widths] = column_widths
          end
        end

        def static_prawn_table_options
          table_options.dup.tap do |options|
            options.delete(:placeholder)
            options.delete(:header)
            TEXT_STYLE_OPTIONS.each { |key| options[:cell].delete(key) }
            options[:cell_style] = options.delete(:cell)
          end
        end

        def convert_cells
          cells.map do |row|
            row.map.with_index do |cell, col|
              convert_cell(cell, col)
            end
          end
        end

        def convert_cell(cell, col)
          style_options = table_options[cell.header ? :header : :cell]
          if cell.single?
            normalize_cell_node(cell.nodes.first, column_content_width(col), style_options)
          else
            cell_table(cell, column_content_width(col), style_options)
          end
        end

        def column_content_width(col)
          width = column_widths[col]
          width -= horizontal_padding if width
          width
        end

        # cell with multiple nodes is represented as single-column table
        def cell_table(cell, width, style_options)
          data = cell.nodes.map { |n| [normalize_cell_node(n, width, style_options)] }
          pdf.make_table(data,
                         width: width,
                         cell_style: {
                           padding: [0, 0, 0, 0],
                           borders: [],
                           border_width: 0,
                           inline_format: true
                         })
        end

        def normalize_cell_node(node, width, style_options = {})
          normalizer = "cell_node_for_#{type_key(node)}"
          if respond_to?(normalizer, true)
            send(normalizer, node, width, style_options)
          else
            ''
          end
        end

        def cell_node_for_list(node, width, _style_options = {})
          opts = options.merge(text: extract_text_cell_style(table_options[:cell]))
          subtable(width) do
            ListBuilder.new(pdf, node, width, opts).make(true)
          end
        end

        def cell_node_for_array(node, width, _style_options = {})
          subtable(width) do
            TableBuilder.new(pdf, node, width, options).make
          end
        end

        def cell_node_for_hash(node, width, style_options = {})
          normalize_cell_hash(node, width, style_options)
        end

        def cell_node_for_string(node, _width, style_options = {})
          style_options.merge(content: node)
        end

        def subtable(width)
          if width.nil? && failover_strategy == :subtable_placeholders
            { content: table_options[:placeholder][:subtable_too_large] }
          else
            yield
          end
        end

        def normalize_cell_hash(node, width, style_options)
          if width.nil? && total_width
            width = total_width - column_width_sum - (columns_without_width - 1) * MIN_COL_WIDTH
          end
          super(node, width, style_options)
        end

        def compute_column_widths
          parse_given_widths
          if total_width
            add_missing_widths
            stretch_to_total_width
          end
        end

        def parse_given_widths
          return if cells.empty?

          @column_widths = Array.new(cells.first.size)
          converter = SizeConverter.new(total_width)
          cells.each do |row|
            row.each_with_index do |cell, col|
              @column_widths[col] ||= converter.parse(cell.width)
            end
          end
        end

        def add_missing_widths
          missing_count = columns_without_width
          if missing_count == 1 ||
             (missing_count > 1 && failover_strategy == :equal_widths)
            distribute_remaing_width(missing_count)
          end
        end

        def columns_without_width
          column_widths.count(&:nil?)
        end

        def column_width_sum
          column_widths.compact.inject(:+) || 0
        end

        def distribute_remaing_width(count)
          equal_width = (total_width - column_width_sum) / count.to_f
          return if equal_width.negative?

          column_widths.map! { |width| width || equal_width }
        end

        def stretch_to_total_width
          sum = column_width_sum
          if columns_without_width.zero? && sum < total_width
            increase_widths(sum)
          elsif sum > total_width
            decrease_widths(sum)
          end
        end

        def increase_widths(sum)
          diff = total_width - sum
          column_widths.map! { |w| w + w / sum * diff }
        end

        def decrease_widths(sum)
          sum += columns_without_width * MIN_COL_WIDTH
          diff = sum - total_width
          column_widths.map! { |w| w ? [w - w / sum * diff, 0].max : nil }
        end

        def failover_on_error
          if failover_strategy == FAILOVER_STRATEGIES.last
            @failover_strategy = nil
          else
            index = FAILOVER_STRATEGIES.index(failover_strategy) || -1
            @failover_strategy = FAILOVER_STRATEGIES[index + 1]
          end
        end

        def horizontal_padding
          @horizontal_padding ||= begin
            padding = table_options[:cell][:padding] || [DEFAULT_CELL_PADDING] * 4
            padding.is_a?(Array) ? padding[1] + padding[3] : padding
          end
        end

        def table_options
          @table_options ||= build_table_options
        end

        def build_table_options
          HashMerger.deep(default_table_options, options[:table] || {}).tap do |opts|
            build_cell_options(opts)
            build_header_options(opts)
          end
        end

        def build_cell_options(opts)
          HashMerger.enhance(opts, :cell, extract_text_cell_style(options[:text] || {}))
          convert_style_options(opts[:cell])
        end

        def build_header_options(opts)
          HashMerger.enhance(opts, :header, opts[:cell])
          convert_style_options(opts[:header])
        end

        def default_table_options
          {
            cell: {
              inline_format: true,
              padding: [DEFAULT_CELL_PADDING] * 4
            },
            header: {},
            placeholder: {
              subtable_too_large: '[nested tables with automatic width are not supported]'
            }
          }
        end
      end
    end
  end
end
