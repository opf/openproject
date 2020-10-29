require 'rexml/document'
require_relative 'Graph'
require_relative 'BarBase'

module SVG
  module Graph
    # === Create presentation quality SVG bar graphs easily
    #
    # = Synopsis
    #
    #   require 'SVG/Graph/Bar'
    #
    #   fields = %w(Jan Feb Mar);
    #   data_sales_02 = [12, 45, 21]
    #
    #   graph = SVG::Graph::Bar.new(
    #     :height => 500,
    #     :width => 300,
    #     :fields => fields
    #   )
    #
    #   graph.add_data(
    #     :data => data_sales_02,
    #     :title => 'Sales 2002'
    #   )
    #
    #   print "Content-type: image/svg+xml\r\n\r\n"
    #   print graph.burn
    #
    # = Description
    #
    # This object aims to allow you to easily create high quality
    # SVG[http://www.w3c.org/tr/svg bar graphs. You can either use the default
    # style sheet or supply your own. Either way there are many options which
    # can be configured to give you control over how the graph is generated -
    # with or without a key, data elements at each point, title, subtitle etc.
    #
    # = Notes
    #
    # The default stylesheet handles upto 12 data sets, if you
    # use more you must create your own stylesheet and add the
    # additional settings for the extra data sets. You will know
    # if you go over 12 data sets as they will have no style and
    # be in black.
    #
    # = Examples
    #
    # * http://germane-software.com/repositories/public/SVG/test/test.rb
    #
    # = See also
    #
    # * SVG::Graph::Graph
    # * SVG::Graph::BarHorizontal
    # * SVG::Graph::Line
    # * SVG::Graph::Pie
    # * SVG::Graph::Plot
    # * SVG::Graph::TimeSeries
    class Bar < BarBase
      include REXML

      protected

      def get_x_labels
        @config[:fields]
      end

      def get_y_labels
        maxvalue = max_value
        minvalue = min_value
        range = maxvalue - minvalue
        # add some padding on top of the graph
        if range == 0
          maxvalue += 10
        else
          maxvalue += range / 20.0
        end
        scale_range = maxvalue - minvalue

        @y_scale_division = scale_divisions || (scale_range / 10.0)

        if scale_integers
          @y_scale_division = @y_scale_division < 1 ? 1 : @y_scale_division.round
        end

        rv = []
        if maxvalue%@y_scale_division != 0
          maxvalue = maxvalue + @y_scale_division
        end
        minvalue.step( maxvalue, @y_scale_division ) {|v| rv << v}
        return rv
      end

      def x_label_offset( width )
        width / 2.0
      end

      def draw_data
        minvalue = min_value
        fieldwidth = field_width

        unit_size = field_height
        bargap = bar_gap ? (fieldwidth < 10 ? fieldwidth / 2 : 10) : 0

        bar_width = fieldwidth - bargap
        bar_width /= @data.length if stack == :side

        bottom = @graph_height

        field_count = 0
        @config[:fields].each_index { |i|
          dataset_count = 0
          for dataset in @data
            total = 0
            dataset[:data].each {|x|
              total += x
            }

            # cases (assume 0 = +ve):
            #   value  min  length
            #    +ve   +ve  value - min
            #    +ve   -ve  value - 0
            #    -ve   -ve  value.abs - 0

            value = dataset[:data][i] / @y_scale_division.to_f

            left = (fieldwidth * field_count)

            length = (value.abs - (minvalue > 0 ? minvalue : 0)) * unit_size
            # top is 0 if value is negative
            top = bottom - (((value < 0 ? 0 : value) - minvalue) * unit_size)
            left += bar_width * dataset_count if stack == :side

            @graph.add_element( "rect", {
              "x" => left.to_s,
              "y" => top.to_s,
              "width" => bar_width.to_s,
              "height" => length.to_s,
              "class" => "fill#{dataset_count+1}"
            })
            value_string = ""
            value_string += (@number_format % dataset[:data][i]) if show_actual_values
            percent = 100.0 * dataset[:data][i] / total
            value_string += " (" + percent.round.to_s + "%)" if show_percent
            make_datapoint_text(left + bar_width/2.0, top - font_size/2, value_string)
            # number format shall not apply to popup (use .to_s conversion)
            add_popup(left + bar_width/2.0, top , value_string)
            dataset_count += 1
          end
          field_count += 1
        }
      end
    end
  end
end
