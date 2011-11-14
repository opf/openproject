#-- encoding: UTF-8
require 'SVG/Graph/Plot'
require 'parsedate'

module SVG
  module Graph
    # === For creating SVG plots of scalar temporal data
    # 
    # = Synopsis
    # 
    #   require 'SVG/Graph/Schedule'
    # 
    #   # Data sets are label, start, end tripples.
    #   data1 = [
    #     "Housesitting", "6/17/04", "6/19/04", 
    #     "Summer Session", "6/15/04", "8/15/04",
    #   ]
    #
    #   graph = SVG::Graph::Schedule.new( {
    #     :width => 640,
    #     :height => 480,
    #     :graph_title => title,
    #     :show_graph_title => true,
    #     :no_css => true,
    #     :scale_x_integers => true,
    #     :scale_y_integers => true,
    #     :min_x_value => 0,
    #     :min_y_value => 0,
    #     :show_data_labels => true,
    #     :show_x_guidelines => true,
    #     :show_x_title => true,
    #     :x_title => "Time",
    #     :stagger_x_labels => true,
    #     :stagger_y_labels => true,
    #     :x_label_format => "%m/%d/%y",
    #   })
    #   
    #   graph.add_data({
    #   	:data => data1,
    # 	  :title => 'Data',
    #   })
    # 
    #   print graph.burn()
    #
    # = Description
    # 
    # Produces a graph of temporal scalar data.
    # 
    # = Examples
    #
    # http://www.germane-software/repositories/public/SVG/test/schedule.rb
    # 
    # = Notes
    # 
    # The default stylesheet handles upto 10 data sets, if you
    # use more you must create your own stylesheet and add the
    # additional settings for the extra data sets. You will know
    # if you go over 10 data sets as they will have no style and
    # be in black.
    #
    # Note that multiple data sets within the same chart can differ in 
    # length, and that the data in the datasets needn't be in order; 
    # they will be ordered by the plot along the X-axis.
    # 
    # The dates must be parseable by ParseDate, but otherwise can be
    # any order of magnitude (seconds within the hour, or years)
    # 
    # = See also
    # 
    # * SVG::Graph::Graph
    # * SVG::Graph::BarHorizontal
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
    class Schedule < Graph
      # In addition to the defaults set by Graph::initialize and
      # Plot::set_defaults, sets:
      # [x_label_format] '%Y-%m-%d %H:%M:%S'
      # [popup_format]  '%Y-%m-%d %H:%M:%S'
      def set_defaults
        init_with(
          :x_label_format     => '%Y-%m-%d %H:%M:%S',
          :popup_format       => '%Y-%m-%d %H:%M:%S',
          :scale_x_divisions  => false,
          :scale_x_integers   => false,
          :bar_gap            => true
        )
      end

      # The format string use do format the X axis labels.
      # See Time::strformat
      attr_accessor :x_label_format
      # Use this to set the spacing between dates on the axis.  The value
      # must be of the form 
      # "\d+ ?(days|weeks|months|years|hours|minutes|seconds)?"
      # 
      # EG:
      #
      #   graph.timescale_divisions = "2 weeks"
      #
      # will cause the chart to try to divide the X axis up into segments of
      # two week periods.
      attr_accessor :timescale_divisions
      # The formatting used for the popups.  See x_label_format
      attr_accessor :popup_format
      attr_accessor :min_x_value
      attr_accessor :scale_x_divisions
      attr_accessor :scale_x_integers
      attr_accessor :bar_gap

      # Add data to the plot.
      #
      #   # A data set with 1 point: Lunch from 12:30 to 14:00
      #   d1 = [ "Lunch", "12:30", "14:00" ] 
      #   # A data set with 2 points: "Cats" runs from 5/11/03 to 7/15/04, and
      #   #                           "Henry V" runs from 6/12/03 to 8/20/03
      #   d2 = [ "Cats", "5/11/03", "7/15/04",
      #          "Henry V", "6/12/03", "8/20/03" ]
      #                                
      #   graph.add_data( 
      #     :data => d1,
      #     :title => 'Meetings'
      #   )
      #   graph.add_data(
      #     :data => d2,
      #     :title => 'Plays'
      #   )
      #
      # Note that the data must be in time,value pairs, and that the date format
      # may be any date that is parseable by ParseDate.
      # Also note that, in this example, we're mixing scales; the data from d1
      # will probably not be discernable if both data sets are plotted on the same
      # graph, since d1 is too granular.
      def add_data data
        @data = [] unless @data
       
        raise "No data provided by #{conf.inspect}" unless data[:data] and
                                                    data[:data].kind_of? Array
        raise "Data supplied must be title,from,to tripples!  "+
          "The data provided contained an odd set of "+
          "data points" unless data[:data].length % 3 == 0
        return if data[:data].length == 0


        y = []
        x_start = []
        x_end = []
        data[:data].each_index {|i|
          im3 = i%3
          if im3 == 0
            y << data[:data][i]
          else
            arr = ParseDate.parsedate( data[:data][i] )
            t = Time.local( *arr[0,6].compact )
            (im3 == 1 ? x_start : x_end) << t.to_i
          end
        }
        sort( x_start, x_end, y )
        @data = [x_start, x_end, y ]
      end


      protected

      def min_x_value=(value)
        arr = ParseDate.parsedate( value )
        @min_x_value = Time.local( *arr[0,6].compact ).to_i
      end


      def format x, y
        Time.at( x ).strftime( popup_format )
      end

      def get_x_labels
        rv = get_x_values.collect { |v| Time.at(v).strftime( x_label_format ) }
      end

      def y_label_offset( height )
        height / -2.0
      end

      def get_y_labels
        @data[2]
      end

      def draw_data
        fieldheight = field_height
        fieldwidth = field_width

        bargap = bar_gap ? (fieldheight < 10 ? fieldheight / 2 : 10) : 0
        subbar_height = fieldheight - bargap
        
        field_count = 1
        y_mod = (subbar_height / 2) + (font_size / 2)
        min,max,div = x_range
        scale = (@graph_width.to_f - font_size*2) / (max-min)
        @data[0].each_index { |i|
          x_start = @data[0][i]
          x_end = @data[1][i]
          y = @graph_height - (fieldheight * field_count)
          bar_width = (x_end-x_start) * scale
          bar_start = x_start * scale - (min * scale)
        
          @graph.add_element( "rect", {
            "x" => bar_start.to_s,
            "y" => y.to_s,
            "width" => bar_width.to_s,
            "height" => subbar_height.to_s,
            "class" => "fill#{field_count+1}"
          })
          field_count += 1
        }
      end

      def get_css
        return <<EOL
/* default fill styles for multiple datasets (probably only use a single dataset on this graph though) */
.key1,.fill1{
	fill: #ff0000;
	fill-opacity: 0.5;
	stroke: none;
	stroke-width: 0.5px;	
}
.key2,.fill2{
	fill: #0000ff;
	fill-opacity: 0.5;
	stroke: none;
	stroke-width: 1px;	
}
.key3,.fill3{
	fill: #00ff00;
	fill-opacity: 0.5;
	stroke: none;
	stroke-width: 1px;	
}
.key4,.fill4{
	fill: #ffcc00;
	fill-opacity: 0.5;
	stroke: none;
	stroke-width: 1px;	
}
.key5,.fill5{
	fill: #00ccff;
	fill-opacity: 0.5;
	stroke: none;
	stroke-width: 1px;	
}
.key6,.fill6{
	fill: #ff00ff;
	fill-opacity: 0.5;
	stroke: none;
	stroke-width: 1px;	
}
.key7,.fill7{
	fill: #00ffff;
	fill-opacity: 0.5;
	stroke: none;
	stroke-width: 1px;	
}
.key8,.fill8{
	fill: #ffff00;
	fill-opacity: 0.5;
	stroke: none;
	stroke-width: 1px;	
}
.key9,.fill9{
	fill: #cc6666;
	fill-opacity: 0.5;
	stroke: none;
	stroke-width: 1px;	
}
.key10,.fill10{
	fill: #663399;
	fill-opacity: 0.5;
	stroke: none;
	stroke-width: 1px;	
}
.key11,.fill11{
	fill: #339900;
	fill-opacity: 0.5;
	stroke: none;
	stroke-width: 1px;	
}
.key12,.fill12{
	fill: #9966FF;
	fill-opacity: 0.5;
	stroke: none;
	stroke-width: 1px;	
}
EOL
      end
      
      private
      def x_range
        max_value = [ @data[0][-1], @data[1].max ].max 
        min_value = [ @data[0][0], @data[1].min ].min
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
        rv = []
        min, max, scale_division = x_range
        if timescale_divisions
          timescale_divisions =~ /(\d+) ?(days|weeks|months|years|hours|minutes|seconds)?/
          division_units = $2 ? $2 : "days"
          amount = $1.to_i
          if amount
            step =  nil
            case division_units
            when "months"
              cur = min
              while cur < max
                rv << cur
                arr = Time.at( cur ).to_a
                arr[4] += amount
                if arr[4] > 12
                  arr[5] += (arr[4] / 12).to_i
                  arr[4] = (arr[4] % 12)
                end
                cur = Time.local(*arr).to_i
              end
            when "years"
              cur = min
              while cur < max
                rv << cur
                arr = Time.at( cur ).to_a
                arr[5] += amount
                cur = Time.local(*arr).to_i
              end
            when "weeks"
              step = 7 * 24 * 60 * 60 * amount
            when "days"
              step = 24 * 60 * 60 * amount
            when "hours"
              step = 60 * 60 * amount
            when "minutes"
              step = 60 * amount
            when "seconds"
              step = amount
            end
            min.step( max, step ) {|v| rv << v} if step

            return rv
          end
        end
        min.step( max, scale_division ) {|v| rv << v}
        return rv
      end
    end
  end
end
