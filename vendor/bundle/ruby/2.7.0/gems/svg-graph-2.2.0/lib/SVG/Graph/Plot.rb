require_relative 'Graph'
require_relative 'DataPoint'

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
    #     :scale_y_integers => true,
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
    #   [ 1,2 ]    # A data set with 1 point: (1,2)
    #   [ 1,2, 5,6] # A data set with 2 points: (1,2) and (5,6)
    # Additional possible notation
    #   [ [1,2], 5,6] # A data set with 2 points: (1,2) and (5,6), mixed notation
    #   [ [1,2], [5,6]] # A data set with 2 points: (1,2) and (5,6), nested array
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
      # [show_data_points] true
      # [area_fill] false
      # [stacked] false, will not have any effect if true
      # [show_lines] true
      # [round_popups] true
      def set_defaults
        init_with(
          :show_data_points  => true,
          :area_fill         => false,
          :stacked           => false,
          :show_lines        => true,
          :round_popups      => true,
          :scale_x_integers  => false,
          :scale_y_integers  => false,
         )
      end

      # Determines the scaling for the X axis divisions.
      #
      #   graph.scale_x_divisions = 2
      #
      # would cause the graph to attempt to generate labels stepped by 2; EG:
      # 0,2,4,6,8...
      # default is automatic such that there are 10 labels
      attr_accessor :scale_x_divisions
      # Determines the scaling for the Y axis divisions.
      #
      #   graph.scale_y_divisions = 0.5
      #
      # would cause the graph to attempt to generate labels stepped by 0.5; EG:
      # 0, 0.5, 1, 1.5, 2, ...
      # default is automatic such that there are 10 labels
      attr_accessor :scale_y_divisions
      # Make the X axis labels integers, default: false
      attr_accessor :scale_x_integers
      # Make the Y axis labels integers, default: false
      attr_accessor :scale_y_integers
      # Fill the area under the line, default: false
      attr_accessor :area_fill
      # Show a small circle on the graph where the line
      # goes from one point to the next. default: true
      attr_accessor :show_data_points
      # Set the minimum value of the X axis, if nil the minimum from data is chosen, default: nil
      attr_accessor :min_x_value
      # Set the maximum value of the X axis, if nil the maximum from data is chosen, default: nil
      attr_accessor :max_x_value
      # Set the minimum value of the Y axis, if nil the minimum from data is chosen, default: nil
      attr_accessor :min_y_value
      # Set the maximum value of the Y axis, if nil the maximum from data is chosen, default: nil
      attr_accessor :max_y_value
      # Show lines connecting data points, default: true
      attr_accessor :show_lines
      # Round value of data points in popups to integer, default: true
      attr_accessor :round_popups


      # Adds data to the plot.  The data must be in X,Y pairs; EG
      #   data_set1 = [ 1, 2 ]    # A data set with 1 point: (1,2)
      #   data_set2 = [ 1,2, 5,6] # A data set with 2 points: (1,2) and (5,6)
      # It's also supported to supply nested array or a mix (flatten is applied to the array); EG
      #   data_set2 = [[1,2], 5,6]
      # or
      #   data_set2 = [[1,2], [5,6]]
      #
      #   graph.add_data({
      #     :data => data_set1,
      #     :title => 'single point'
      #   })
      #   graph.add_data({
      #     :data => data_set2,
      #     :title => 'two points'
      #   })
      def add_data(conf)
	      @data ||= []
        raise "No data provided by #{conf.inspect}" unless conf[:data] and
          conf[:data].kind_of? Array
        # support array of arrays and flatten it
        conf[:data] = conf[:data].flatten
        # check that we have pairs of values
        raise "Data supplied must be x,y pairs!  "+
          "The data provided contained an odd set of "+
          "data points" unless conf[:data].length % 2 == 0

        # remove nil values
        conf[:data] = conf[:data].compact

        return if conf[:data].length == 0

        conf[:description] ||= Array.new(conf[:data].size/2)
        if conf[:description].size != conf[:data].size/2
          raise "Description for popups does not have same size as provided data: #{conf[:description].size} vs #{conf[:data].size/2}"
        end

        x = []
        y = []
        conf[:data].each_index {|i|
          (i%2 == 0 ? x : y) << conf[:data][i]
        }
        sort( x, y, conf[:description] )
        conf[:data] = [x,y]
        # at the end data looks like:
        # [
        #   [all x values],
        #   [all y values]
        # ]
        @data << conf
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

      def max_x_range
        max_value = @data.collect{|x| x[:data][X][-1] }.max
        max_value = max_value > max_x_value ? max_value : max_x_value if max_x_value
        max_value
      end

      def min_x_range
        min_value = @data.collect{|x| x[:data][X][0] }.min
        min_value = min_value < min_x_value ? min_value : min_x_value if min_x_value
        min_value
      end

      def x_label_range
        max_value = max_x_range
        min_value = min_x_range
        range = max_value - min_value
        # add some padding on right
        if range == 0
          max_value += 10
        else
          max_value += range / 20.0
        end
        scale_range = max_value - min_value

        scale_division = scale_x_divisions || (scale_range / 10.0)
        @x_offset = 0

        if scale_x_integers
          scale_division = scale_division < 1 ? 1 : scale_division.round
          @x_offset = min_value.to_f - min_value.floor
          min_value = min_value.floor
        end

        [min_value, max_value, scale_division]
      end

      def get_x_values
        min_value, max_value, @x_scale_division = x_label_range
        rv = []
        min_value.step( max_value + @x_scale_division , @x_scale_division ) {|v| rv << v}
        return rv
      end
      alias :get_x_labels :get_x_values

      def field_width
        # exclude values which are outside max_x_range
        values = get_x_values
        @graph_width.to_f / (values.length - 1 ) # -1 is to use entire x-axis
                                                 # otherwise there is always 1 division unused
      end


      def max_y_range
        max_value = @data.collect{|x| x[:data][Y].max }.max
        max_value = max_value > max_y_value ? max_value : max_y_value if max_y_value
        max_value
      end

      def min_y_range
        min_value = @data.collect{|x| x[:data][Y].min }.min
        min_value = min_value < min_y_value ? min_value : min_y_value if min_y_value
        min_value
      end

      def y_label_range
        max_value = max_y_range
        min_value = min_y_range
        range = max_value - min_value
        # add some padding on top
        if range == 0
          max_value += 10
        else
          max_value += range / 20.0
        end
        scale_range = max_value - min_value

        scale_division = scale_y_divisions || (scale_range / 10.0)
        @y_offset = 0

        if scale_y_integers
          scale_division = scale_division < 1 ? 1 : scale_division.round
          @y_offset = (min_value.to_f - min_value.floor).to_f
          min_value = min_value.floor
        end

        return [min_value, max_value, scale_division]
      end

      def get_y_values
        min_value, max_value, @y_scale_division = y_label_range
        if max_value != min_value
          while (max_value - min_value) < @y_scale_division
            @y_scale_division /= 10.0
          end
        end
        rv = []
        min_value.step( max_value + @y_scale_division, @y_scale_division ) {|v| rv << v}
        rv << rv[0] + 1 if rv.length == 1
        return rv
      end
      alias :get_y_labels :get_y_values

      def field_height
        # exclude values which are outside max_x_range
        values = get_y_values
        max = max_y_range
        if values.length == 1
          dx = values[-1]
        else
          dx = (max - values[-1]).to_f / (values[-1] - values[-2])
        end
        @graph_height.to_f / values.length
      end

      def calc_coords(x, y)
        coords = {:x => 0, :y => 0}
        # scale the coordinates, use float division / multiplication
        # otherwise the point will be place inaccurate
        coords[:x] = (x + @x_offset)/@x_scale_division.to_f * field_width
        coords[:y] = @graph_height - (y + @y_offset)/@y_scale_division.to_f * field_height
        return coords
      end

      def draw_data
        line = 1

        x_min = min_x_range
        x_max = max_x_range
        y_min = min_y_range
        y_max = max_y_range

        for data in @data
          x_points = data[:data][X]
          y_points = data[:data][Y]

          lpath = "L"
          x_start = 0
          y_start = 0
          x_points.each_index { |idx|
            c = calc_coords(x_points[idx] -  x_min, y_points[idx] -  y_min)
            x_start, y_start = c[:x],c[:y] if idx == 0
            lpath << "#{c[:x]} #{c[:y]} "
          }

          if area_fill
            @graph.add_element( "path", {
              "d" => "M#{x_start} #@graph_height #{lpath} V#@graph_height Z",
              "class" => "fill#{line}"
            })
          end

          if show_lines
            @graph.add_element( "path", {
              "d" => "M#{x_start} #{y_start} #{lpath}",
              "class" => "line#{line}"
            })
          end

          if show_data_points || show_data_values || add_popups
            x_points.each_index { |idx|
              c = calc_coords(x_points[idx] -  x_min, y_points[idx] -  y_min)
              if show_data_points
                DataPoint.new(c[:x], c[:y], line).shape(data[:description][idx]).each{|s|
                  @graph.add_element( *s )
                }
              end
              make_datapoint_text( c[:x], c[:y]-6, y_points[idx] )
              add_popup(c[:x], c[:y], format( x_points[idx], y_points[idx], data[:description][idx]))
            }
          end
          line += 1
        end
      end

      # returns the formatted string which is added as popup information
      def format x, y, desc
        info = []
        info << (round_popups ? x.round : @number_format % x )
        info << (round_popups ? y.round : @number_format % y )
        info << desc
        "(#{info.compact.join(', ')})"
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
	stroke: #cc6666;
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
