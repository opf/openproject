require 'SVG/Graph/Graph'

module SVG
  module Graph
    # === For creating SVG plots of scalar data
    # 
    # = Synopsis
    # 
    #   require 'SVG/Graph/Plot'
    # 
    #   # Data sets are x,y pairs
    #   # Note that multiple data sets can differ in length, and that the
    #   # data in the datasets needn't be in order; they will be ordered
    #   # by the plot along the X-axis.
    #   projection = [
    #     6, 11,    0, 5,   18, 7,   1, 11,   13, 9,   1, 2,   19, 0,   3, 13,
    #     7, 9 
    #   ]
    #   actual = [
    #     0, 18,    8, 15,    9, 4,   18, 14,   10, 2,   11, 6,  14, 12,   
    #     15, 6,   4, 17,   2, 12
    #   ]
    #   
    #   graph = SVG::Graph::Plot.new({
    #   	:height => 500,
    #    	:width => 300,
    #     :key => true,
    #     :scale_x_integers => true,
    #     :scale_y_integerrs => true,
    #   })
    #   
    #   graph.add_data({
    #   	:data => projection
    # 	  :title => 'Projected',
    #   })
    # 
    #   graph.add_data({
    #   	:data => actual,
    # 	  :title => 'Actual',
    #   })
    #   
    #   print graph.burn()
    # 
    # = Description
    # 
    # Produces a graph of scalar data.
    # 
    # This object aims to allow you to easily create high quality
    # SVG[http://www.w3c.org/tr/svg] scalar plots. You can either use the
    # default style sheet or supply your own. Either way there are many options
    # which can be configured to give you control over how the graph is
    # generated - with or without a key, data elements at each point, title,
    # subtitle etc.
    #
    # = Examples
    # 
    # http://www.germane-software/repositories/public/SVG/test/plot.rb
    # 
    # = Notes
    # 
    # The default stylesheet handles upto 10 data sets, if you
    # use more you must create your own stylesheet and add the
    # additional settings for the extra data sets. You will know
    # if you go over 10 data sets as they will have no style and
    # be in black.
    #
    # Unlike the other types of charts, data sets must contain x,y pairs:
    #
    #   [ 1, 2 ]    # A data set with 1 point: (1,2)
    #   [ 1,2, 5,6] # A data set with 2 points: (1,2) and (5,6)  
    # 
    # = See also
    # 
    # * SVG::Graph::Graph
    # * SVG::Graph::BarHorizontal
    # * SVG::Graph::Bar
    # * SVG::Graph::Line
    # * SVG::Graph::Pie
    # * SVG::Graph::TimeSeries
    #
    # == Author
    #
    # Sean E. Russell <serATgermaneHYPHENsoftwareDOTcom>
    #
    # Copyright 2004 Sean E. Russell
    # This software is available under the Ruby license[LICENSE.txt]
    #
    class Plot < Graph

      # In addition to the defaults set by Graph::initialize, sets
      # [show_data_values] true
      # [show_data_points] true
      # [area_fill] false
      # [stacked] false
      def set_defaults
        init_with(
                  :show_data_values  => true,
                  :show_data_points  => true,
                  :area_fill         => false,
                  :stacked           => false
                 )
                 self.top_align = self.right_align = self.top_font = self.right_font = 1
      end

      # Determines the scaling for the X axis divisions.
      #
      #   graph.scale_x_divisions = 2
      #
      # would cause the graph to attempt to generate labels stepped by 2; EG:
      # 0,2,4,6,8...
      attr_accessor :scale_x_divisions
      # Determines the scaling for the Y axis divisions.
      #
      #   graph.scale_y_divisions = 0.5
      #
      # would cause the graph to attempt to generate labels stepped by 0.5; EG:
      # 0, 0.5, 1, 1.5, 2, ...
      attr_accessor :scale_y_divisions 
      # Make the X axis labels integers
      attr_accessor :scale_x_integers 
      # Make the Y axis labels integers
      attr_accessor :scale_y_integers 
      # Fill the area under the line
      attr_accessor :area_fill 
      # Show a small circle on the graph where the line
      # goes from one point to the next.
      attr_accessor :show_data_points
      # Set the minimum value of the X axis
      attr_accessor :min_x_value 
      # Set the minimum value of the Y axis
      attr_accessor :min_y_value


      # Adds data to the plot.  The data must be in X,Y pairs; EG
      #   [ 1, 2 ]    # A data set with 1 point: (1,2)
      #   [ 1,2, 5,6] # A data set with 2 points: (1,2) and (5,6)  
      def add_data data
        @data = [] unless @data

        raise "No data provided by #{conf.inspect}" unless data[:data] and
        data[:data].kind_of? Array
        raise "Data supplied must be x,y pairs!  "+
          "The data provided contained an odd set of "+
          "data points" unless data[:data].length % 2 == 0
        return if data[:data].length == 0

        x = []
        y = []
        data[:data].each_index {|i|
          (i%2 == 0 ? x : y) << data[:data][i]
        }
        sort( x, y )
        data[:data] = [x,y]
        @data << data
      end


      protected

      def keys
        @data.collect{ |x| x[:title] }
      end

      def calculate_left_margin
        super
        label_left = get_x_labels[0].to_s.length / 2 * font_size * 0.6
        @border_left = label_left if label_left > @border_left
      end

      def calculate_right_margin
        super
        label_right = get_x_labels[-1].to_s.length / 2 * font_size * 0.6
        @border_right = label_right if label_right > @border_right
      end


      X = 0
      Y = 1
      def x_range
        max_value = @data.collect{|x| x[:data][X][-1] }.max
        min_value = @data.collect{|x| x[:data][X][0] }.min
        min_value = min_value<min_x_value ? min_value : min_x_value if min_x_value

        range = max_value - min_value
        right_pad = range == 0 ? 10 : range / 20.0
        scale_range = (max_value + right_pad) - min_value

        scale_division = scale_x_divisions || (scale_range / 10.0)

        if scale_x_integers
          scale_division = scale_division < 1 ? 1 : scale_division.round
        end

        [min_value, max_value, scale_division]
      end

      def get_x_values
        min_value, max_value, scale_division = x_range
        rv = []
        min_value.step( max_value, scale_division ) {|v| rv << v}
        return rv
      end
      alias :get_x_labels :get_x_values

      def field_width
        values = get_x_values
        max = @data.collect{|x| x[:data][X][-1]}.max
        dx = (max - values[-1]).to_f / (values[-1] - values[-2])
        (@graph_width.to_f - font_size*2*right_font) /
          (values.length + dx - right_align)
      end


      def y_range
        max_value = @data.collect{|x| x[:data][Y].max }.max
        min_value = @data.collect{|x| x[:data][Y].min }.min
        min_value = min_value<min_y_value ? min_value : min_y_value if min_y_value

        range = max_value - min_value
        top_pad = range == 0 ? 10 : range / 20.0
        scale_range = (max_value + top_pad) - min_value

        scale_division = scale_y_divisions || (scale_range / 10.0)

        if scale_y_integers
          scale_division = scale_division < 1 ? 1 : scale_division.round
        end

        return [min_value, max_value, scale_division]
      end

      def get_y_values
        min_value, max_value, scale_division = y_range
        rv = []
        min_value.step( max_value, scale_division ) {|v| rv << v}
        return rv
      end
      alias :get_y_labels :get_y_values

      def field_height
        values = get_y_values
        max = @data.collect{|x| x[:data][Y].max }.max
        if values.length == 1
          dx = values[-1]
        else
          dx = (max - values[-1]).to_f / (values[-1] - values[-2])
        end
        (@graph_height.to_f - font_size*2*top_font) /
          (values.length + dx - top_align)
      end

      def draw_data
        line = 1

        x_min, x_max, x_div = x_range
        y_min, y_max, y_div = y_range
        x_step = (@graph_width.to_f - font_size*2) / (x_max-x_min)
        y_step = (@graph_height.to_f -  font_size*2) / (y_max-y_min)

        for data in @data
          x_points = data[:data][X]
          y_points = data[:data][Y]

          lpath = "L"
          x_start = 0
          y_start = 0
          x_points.each_index { |idx|
            x = (x_points[idx] -  x_min) * x_step
            y = @graph_height - (y_points[idx] -  y_min) * y_step
            x_start, y_start = x,y if idx == 0
            lpath << "#{x} #{y} "
          }

          if area_fill
            @graph.add_element( "path", {
              "d" => "M#{x_start} #@graph_height #{lpath} V#@graph_height Z",
              "class" => "fill#{line}"
            })
          end

          @graph.add_element( "path", {
            "d" => "M#{x_start} #{y_start} #{lpath}",
            "class" => "line#{line}"
          })

          if show_data_points || show_data_values
            x_points.each_index { |idx|
              x = (x_points[idx] -  x_min) * x_step
              y = @graph_height - (y_points[idx] -  y_min) * y_step
              if show_data_points
                @graph.add_element( "circle", {
                  "cx" => x.to_s,
                  "cy" => y.to_s,
                  "r" => "2.5",
                  "class" => "dataPoint#{line}"
                })
                add_popup(x, y, format( x_points[idx], y_points[idx] )) if add_popups
              end
              make_datapoint_text( x, y-6, y_points[idx] ) if show_data_values
            }
          end
          line += 1
        end
      end

      def format x, y
        "(#{(x * 100).to_i / 100}, #{(y * 100).to_i / 100})"
      end
      
      def get_css
        return <<EOL
/* default line styles */
.line1{
	fill: none;
	stroke: #ff0000;
	stroke-width: 1px;	
}
.line2{
	fill: none;
	stroke: #0000ff;
	stroke-width: 1px;	
}
.line3{
	fill: none;
	stroke: #00ff00;
	stroke-width: 1px;	
}
.line4{
	fill: none;
	stroke: #ffcc00;
	stroke-width: 1px;	
}
.line5{
	fill: none;
	stroke: #00ccff;
	stroke-width: 1px;	
}
.line6{
	fill: none;
	stroke: #ff00ff;
	stroke-width: 1px;	
}
.line7{
	fill: none;
	stroke: #00ffff;
	stroke-width: 1px;	
}
.line8{
	fill: none;
	stroke: #ffff00;
	stroke-width: 1px;	
}
.line9{
	fill: none;
	stroke: #ccc6666;
	stroke-width: 1px;	
}
.line10{
	fill: none;
	stroke: #663399;
	stroke-width: 1px;	
}
.line11{
	fill: none;
	stroke: #339900;
	stroke-width: 1px;	
}
.line12{
	fill: none;
	stroke: #9966FF;
	stroke-width: 1px;	
}
/* default fill styles */
.fill1{
	fill: #cc0000;
	fill-opacity: 0.2;
	stroke: none;
}
.fill2{
	fill: #0000cc;
	fill-opacity: 0.2;
	stroke: none;
}
.fill3{
	fill: #00cc00;
	fill-opacity: 0.2;
	stroke: none;
}
.fill4{
	fill: #ffcc00;
	fill-opacity: 0.2;
	stroke: none;
}
.fill5{
	fill: #00ccff;
	fill-opacity: 0.2;
	stroke: none;
}
.fill6{
	fill: #ff00ff;
	fill-opacity: 0.2;
	stroke: none;
}
.fill7{
	fill: #00ffff;
	fill-opacity: 0.2;
	stroke: none;
}
.fill8{
	fill: #ffff00;
	fill-opacity: 0.2;
	stroke: none;
}
.fill9{
	fill: #cc6666;
	fill-opacity: 0.2;
	stroke: none;
}
.fill10{
	fill: #663399;
	fill-opacity: 0.2;
	stroke: none;
}
.fill11{
	fill: #339900;
	fill-opacity: 0.2;
	stroke: none;
}
.fill12{
	fill: #9966FF;
	fill-opacity: 0.2;
	stroke: none;
}
/* default line styles */
.key1,.dataPoint1{
	fill: #ff0000;
	stroke: none;
	stroke-width: 1px;	
}
.key2,.dataPoint2{
	fill: #0000ff;
	stroke: none;
	stroke-width: 1px;	
}
.key3,.dataPoint3{
	fill: #00ff00;
	stroke: none;
	stroke-width: 1px;	
}
.key4,.dataPoint4{
	fill: #ffcc00;
	stroke: none;
	stroke-width: 1px;	
}
.key5,.dataPoint5{
	fill: #00ccff;
	stroke: none;
	stroke-width: 1px;	
}
.key6,.dataPoint6{
	fill: #ff00ff;
	stroke: none;
	stroke-width: 1px;	
}
.key7,.dataPoint7{
	fill: #00ffff;
	stroke: none;
	stroke-width: 1px;	
}
.key8,.dataPoint8{
	fill: #ffff00;
	stroke: none;
	stroke-width: 1px;	
}
.key9,.dataPoint9{
	fill: #cc6666;
	stroke: none;
	stroke-width: 1px;	
}
.key10,.dataPoint10{
	fill: #663399;
	stroke: none;
	stroke-width: 1px;	
}
.key11,.dataPoint11{
	fill: #339900;
	stroke: none;
	stroke-width: 1px;	
}
.key12,.dataPoint12{
	fill: #9966FF;
	stroke: none;
	stroke-width: 1px;	
}
EOL
      end

    end
  end
end
