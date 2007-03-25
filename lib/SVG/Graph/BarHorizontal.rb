require 'rexml/document'
require 'SVG/Graph/BarBase'

module SVG
  module Graph
    # === Create presentation quality SVG horitonzal bar graphs easily
    # 
    # = Synopsis
    # 
    #   require 'SVG/Graph/BarHorizontal'
    #   
    #   fields = %w(Jan Feb Mar)
    #   data_sales_02 = [12, 45, 21]
    #   
    #   graph = SVG::Graph::BarHorizontal.new({
    #     :height => 500,
    #     :width => 300,
    #     :fields => fields,
    #   })
    #   
    #   graph.add_data({
    #     :data => data_sales_02,
    #     :title => 'Sales 2002',
    #   })
    #   
    #   print "Content-type: image/svg+xml\r\n\r\n"
    #   print graph.burn
    # 
    # = Description
    # 
    # This object aims to allow you to easily create high quality
    # SVG horitonzal bar graphs. You can either use the default style sheet
    # or supply your own. Either way there are many options which can
    # be configured to give you control over how the graph is
    # generated - with or without a key, data elements at each point,
    # title, subtitle etc.
    # 
    # = Examples
    # 
    # * http://germane-software.com/repositories/public/SVG/test/test.rb
    # 
    # = See also
    # 
    # * SVG::Graph::Graph
    # * SVG::Graph::Bar
    # * SVG::Graph::Line
    # * SVG::Graph::Pie
    # * SVG::Graph::Plot
    # * SVG::Graph::TimeSeries
    #
    # == Author
    #
    # Sean E. Russell <serATgermaneHYPHENsoftwareDOTcom>
    #
    # Copyright 2004 Sean E. Russell
    # This software is available under the Ruby license[LICENSE.txt]
    #
    class BarHorizontal < BarBase
      # In addition to the defaults set in BarBase::set_defaults, sets
      # [rotate_y_labels] true
      # [show_x_guidelines] true
      # [show_y_guidelines] false
      def set_defaults
        super
        init_with( 
          :rotate_y_labels    => true,
          :show_x_guidelines  => true,
          :show_y_guidelines  => false
        )
        self.right_align = self.right_font = 1
      end
  
      protected

      def get_x_labels
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

      def get_y_labels
        @config[:fields]
      end

      def y_label_offset( height )
        height / -2.0
      end

      def draw_data
        minvalue = min_value
        fieldheight = field_height
        fieldwidth = (@graph_width.to_f - font_size*2*right_font ) /
                        (get_x_labels.max - get_x_labels.min )
        bargap = bar_gap ? (fieldheight < 10 ? fieldheight / 2 : 10) : 0

        subbar_height = fieldheight - bargap
        subbar_height /= @data.length if stack == :side
        
        field_count = 1
        y_mod = (subbar_height / 2) + (font_size / 2)
        @config[:fields].each_index { |i|
          dataset_count = 0
          for dataset in @data
            y = @graph_height - (fieldheight * field_count)
            y += (subbar_height * dataset_count) if stack == :side
            x = (dataset[:data][i] - minvalue) * fieldwidth

            @graph.add_element( "path", {
              "d" => "M0 #{y} H#{x} v#{subbar_height} H0 Z",
              "class" => "fill#{dataset_count+1}"
            })
            make_datapoint_text( 
              x+5, y+y_mod, dataset[:data][i], "text-anchor: start; "
              )
            dataset_count += 1
          end
          field_count += 1
        }
      end
    end
  end
end
