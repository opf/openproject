require_relative 'Graph'

module SVG
  module Graph
    # === Create presentation quality SVG line graphs easily
    #
    # = Synopsis
    #
    #   require 'SVG/Graph/Line'
    #
    #   fields = %w(Jan Feb Mar);
    #   data_sales_02 = [12, 45, 21]
    #   data_sales_03 = [15, 30, 40]
    #
    #   graph = SVG::Graph::Line.new({
    #   	:height => 500,
    #    	:width => 300,
    # 	  :fields => fields,
    #   })
    #
    #   graph.add_data({
    #   	:data => data_sales_02,
    # 	  :title => 'Sales 2002',
    #   })
    #
    #   graph.add_data({
    #   	:data => data_sales_03,
    # 	  :title => 'Sales 2003',
    #   })
    #
    #   print "Content-type: image/svg+xml\r\n\r\n";
    #   print graph.burn();
    #
    # = Description
    #
    # This object aims to allow you to easily create high quality
    # SVG line graphs. You can either use the default style sheet
    # or supply your own. Either way there are many options which can
    # be configured to give you control over how the graph is
    # generated - with or without a key, data elements at each point,
    # title, subtitle etc.
    #
    # = Examples
    #
    # http://www.germane-software/repositories/public/SVG/test/single.rb
    #
    # = Notes
    # Only number of fileds datapoints will be drawn, additional data values
    # are ignored. Nil values in data are  skipped and
    # interpolated as straight line to the next datapoint.
    #
    # The default stylesheet handles upto 10 data sets, if you
    # use more you must create your own stylesheet and add the
    # additional settings for the extra data sets. You will know
    # if you go over 10 data sets as they will have no style and
    # be in black.
    #
    # = See also
    #
    # * SVG::Graph::Graph
    # * SVG::Graph::BarHorizontal
    # * SVG::Graph::Bar
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
    class Line < SVG::Graph::Graph
      #    Show a small circle on the graph where the line
      #    goes from one point to the next.
      attr_accessor :show_data_points
      #    Accumulates each data set. (i.e. Each point increased by sum of
      #   all previous series at same point). Default is 0, set to '1' to show.
      attr_accessor :stacked
      # Fill in the area under the plot if true
      attr_accessor :area_fill

      # The constructor takes a hash reference, :fields (the names for each
      # field on the X axis) MUST be set, all other values are defaulted to
      # those shown above - with the exception of style_sheet which defaults
      # to using the internal style sheet.
      def initialize config
          raise "fields was not supplied or is empty" unless config[:fields] &&
          config[:fields].kind_of?(Array) &&
          config[:fields].length > 0
          super
      end

      # In addition to the defaults set in Graph::initialize, sets
      # [show_data_points] true
      # [show_data_values] true
      # [stacked] false
      # [area_fill] false
      def set_defaults
        init_with(
          :show_data_points   => true,
          :show_data_values   => true,
          :stacked            => false,
          :area_fill          => false
        )
      end

      protected

      def max_value
        max = 0
        if stacked
          sums = Array.new(@config[:fields].length).fill(0)

          @data.each do |data|
            sums.each_index do |i|
              sums[i] += data[:data][i].to_f
            end
          end
          max = sums.max
        else
          # compact removes nil values when computing the max
          max = @data.collect{ |x|
            x[:data].compact.max
          }.max
        end

        return max
      end

      def min_value
        min = 0
        # compact removes nil values
        if (!min_scale_value.nil?) then
          min = min_scale_value
        elsif (stacked == true) then
          min = @data[-1][:data].compact.min
        else
          min = @data.collect{|x| x[:data].compact.min}.min
        end

        return min
      end

      def get_x_labels
        @config[:fields]
      end

      def calculate_left_margin
        super
        label_left = @config[:fields][0].length / 2 * font_size * 0.6
        @border_left = label_left if label_left > @border_left
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
        @y_offset = 0

        if scale_integers
          @y_scale_division = @y_scale_division < 1 ? 1 : @y_scale_division.round
          @y_offset = (minvalue.to_f - minvalue.floor).to_f
          minvalue = minvalue.floor
        end

        rv = []

        minvalue.step( maxvalue, @y_scale_division ) {|v| rv << v}
        return rv
      end

      def calc_coords(field, value, width = field_width, height = field_height)
        coords = {:x => 0, :y => 0}
        coords[:x] = width * field
        # make sure we do float division, otherwise coords get messed up
        coords[:y] = @graph_height - (value + @y_offset)/@y_scale_division.to_f * height
        return coords
      end

      def draw_data
        minvalue = min_value
        fieldheight = field_height
        fieldwidth = field_width
        line = @data.length
        # always zero for filling areas
        prev_sum = Array.new(@config[:fields].length).fill(-@y_offset)
        # cumulated sum (used for stacked graphs)
        cum_sum = Array.new(@config[:fields].length).fill(nil)

        for data in @data.reverse
          lpath = ""
          apath = ""

          # reset cum_sum if we are not in a stacked graph
          if not stacked then cum_sum.fill(nil) end

          # only consider as many datapoints as we have fields
          @config[:fields].each_index do |i|
            next if data[:data][i].nil?
            if cum_sum[i].nil? #first time init
              cum_sum[i] = data[:data][i] - minvalue
            else # in case of stacked
              cum_sum[i] += data[:data][i]
            end
            c = calc_coords(i, cum_sum[i], fieldwidth, fieldheight)
            lpath << "#{c[:x]} #{c[:y]} "
          end

          if area_fill
            if stacked then
              (prev_sum.length - 1).downto 0 do |i|
                next if prev_sum[i].nil?
                c = calc_coords(i, prev_sum[i], fieldwidth, fieldheight)

                apath << "#{c[:x]} #{c[:y]} "
              end

              c = calc_coords(0, prev_sum[0], fieldwidth, fieldheight)
            else
              apath = "V#@graph_height"
              c = calc_coords(0, -@y_offset, fieldwidth, fieldheight)
            end

            @graph.add_element("path", {
              "d" => "M#{c[:x]} #{c[:y]} L" + lpath + apath + "Z",
              "class" => "fill#{line}"
            })
          end

          @graph.add_element("path", {
            "d" => "M0 #@graph_height L" + lpath,
            "class" => "line#{line}"
          })

          if show_data_points || show_data_values || add_popups
            cum_sum.each_index do |i|
              # skip datapoint if nil
              next if cum_sum[i].nil?
              c = calc_coords(i, cum_sum[i], fieldwidth, fieldheight)
              if show_data_points
                @graph.add_element( "circle", {
                  "cx" => c[:x].to_s,
                  "cy" => c[:y].to_s,
                  "r" => "2.5",
                  "class" => "dataPoint#{line}"
                })
              end

              make_datapoint_text( c[:x], c[:y] - font_size/2, cum_sum[i] + minvalue)
              # number format shall not apply to popup (use .to_s conversion)
              add_popup(c[:x], c[:y], (cum_sum[i] + minvalue).to_s)
            end
          end

          prev_sum = cum_sum.dup
          line -= 1
        end
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
