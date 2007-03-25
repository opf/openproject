require 'rexml/document'
require 'SVG/Graph/Graph'
require 'SVG/Graph/BarBase'

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

      # See Graph::initialize and BarBase::set_defaults
      def set_defaults 
        super
        self.top_align = self.top_font = 1
      end

      protected

      def get_x_labels
        @config[:fields]
      end

      def get_y_labels
        maxvalue = max_value
        minvalue = min_value
        range = maxvalue - minvalue

        top_pad = range == 0 ? 10 : range / 20.0
        scale_range = (maxvalue + top_pad) - minvalue

        scale_division = scale_divisions || (scale_range / 10.0)

        if scale_integers
          scale_division = scale_division < 1 ? 1 : scale_division.round
        end

        rv = []
        maxvalue = maxvalue%scale_division == 0 ? 
          maxvalue : maxvalue + scale_division
        minvalue.step( maxvalue, scale_division ) {|v| rv << v}
        return rv
      end

      def x_label_offset( width )
        width / 2.0
      end

      def draw_data
        fieldwidth = field_width
        maxvalue = max_value
        minvalue = min_value

        fieldheight =  (@graph_height.to_f - font_size*2*top_font) / 
                          (get_y_labels.max - get_y_labels.min)
        bargap = bar_gap ? (fieldwidth < 10 ? fieldwidth / 2 : 10) : 0

        subbar_width = fieldwidth - bargap
        subbar_width /= @data.length if stack == :side
        x_mod = (@graph_width-bargap)/2 - (stack==:side ? subbar_width/2 : 0)
        # Y1
        p2 = @graph_height
        # to X2
        field_count = 0
        @config[:fields].each_index { |i|
          dataset_count = 0
          for dataset in @data
            # X1
            p1 = (fieldwidth * field_count)
            # to Y2
            p3 = @graph_height - ((dataset[:data][i] - minvalue) * fieldheight)
            p1 += subbar_width * dataset_count if stack == :side
            @graph.add_element( "path", {
              "class" => "fill#{dataset_count+1}",
              "d" => "M#{p1} #{p2} V#{p3} h#{subbar_width} V#{p2} Z"
            })
            make_datapoint_text(
              p1 + subbar_width/2.0,
              p3 - 6,
              dataset[:data][i].to_s)
            dataset_count += 1
          end
          field_count += 1
        }
      end
    end
  end
end
