#-- encoding: UTF-8
require 'SVG/Graph/Graph'

module SVG
  module Graph
    # === Create presentation quality SVG pie graphs easily
    # 
    # == Synopsis
    # 
    #   require 'SVG/Graph/Pie'
    # 
    #   fields = %w(Jan Feb Mar)
    #   data_sales_02 = [12, 45, 21]
    #   
    #   graph = SVG::Graph::Pie.new({
    #   	:height => 500,
    # 	  :width  => 300,
    # 	  :fields => fields,
    #   })
    #   
    #   graph.add_data({
    #   	:data => data_sales_02,
    # 	  :title => 'Sales 2002',
    #   })
    #   
    #   print "Content-type: image/svg+xml\r\n\r\n"
    #   print graph.burn();
    # 
    # == Description
    # 
    # This object aims to allow you to easily create high quality
    # SVG pie graphs. You can either use the default style sheet
    # or supply your own. Either way there are many options which can
    # be configured to give you control over how the graph is
    # generated - with or without a key, display percent on pie chart,
    # title, subtitle etc.
    #
    # = Examples
    # 
    # http://www.germane-software/repositories/public/SVG/test/single.rb
    # 
    # == See also
    #
    # * SVG::Graph::Graph
    # * SVG::Graph::BarHorizontal
    # * SVG::Graph::Bar
    # * SVG::Graph::Line
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
    class Pie < Graph
      # Defaults are those set by Graph::initialize, and
      # [show_shadow] true
      # [shadow_offset] 10
      # [show_data_labels] false
      # [show_actual_values] false
      # [show_percent] true
      # [show_key_data_labels] true
      # [show_key_actual_values] true
      # [show_key_percent] false
      # [expanded] false
      # [expand_greatest] false
      # [expand_gap] 10
      # [show_x_labels] false
      # [show_y_labels] false
      # [datapoint_font_size] 12
      def set_defaults
        init_with(
          :show_shadow		        => true,
          :shadow_offset	        => 10, 
          
          :show_data_labels	      => false,
          :show_actual_values     => false,
          :show_percent		        => true,

          :show_key_data_labels	  => true,
          :show_key_actual_values => true,
          :show_key_percent		    => false,
          
          :expanded				        => false,
          :expand_greatest		    => false,
          :expand_gap             => 10,
          
          :show_x_labels          => false,
          :show_y_labels          => false,
          :datapoint_font_size    => 12
        )
        @data = []
      end

      # Adds a data set to the graph.
      #
      #   graph.add_data( { :data => [1,2,3,4] } )
      #
      # Note that the :title is not necessary.  If multiple
      # data sets are added to the graph, the pie chart will
      # display the +sums+ of the data.  EG:
      #
      #   graph.add_data( { :data => [1,2,3,4] } )
      #   graph.add_data( { :data => [2,3,5,9] } )
      #
      # is the same as:
      #
      #   graph.add_data( { :data => [3,5,8,13] } )
      def add_data arg
        arg[:data].each_index {|idx|
          @data[idx] = 0 unless @data[idx]
          @data[idx] += arg[:data][idx]
        }
      end

      # If true, displays a drop shadow for the chart
      attr_accessor :show_shadow 
      # Sets the offset of the shadow from the pie chart
      attr_accessor :shadow_offset
      # If true, display the data labels on the chart
      attr_accessor :show_data_labels 
      # If true, display the actual field values in the data labels
      attr_accessor :show_actual_values 
      # If true, display the percentage value of each pie wedge in the data
      # labels
      attr_accessor :show_percent
      # If true, display the labels in the key
      attr_accessor :show_key_data_labels 
      # If true, display the actual value of the field in the key
      attr_accessor :show_key_actual_values 
      # If true, display the percentage value of the wedges in the key
      attr_accessor :show_key_percent
      # If true, "explode" the pie (put space between the wedges)
      attr_accessor :expanded 
      # If true, expand the largest pie wedge
      attr_accessor :expand_greatest 
      # The amount of space between expanded wedges
      attr_accessor :expand_gap 
      # The font size of the data point labels
      attr_accessor :datapoint_font_size


      protected

      def add_defs defs
        gradient = defs.add_element( "filter", {
          "id"=>"dropshadow",
          "width" => "1.2",
          "height" => "1.2",
        } )
        gradient.add_element( "feGaussianBlur", {
          "stdDeviation" => "4",
          "result" => "blur"
        })
      end

      # We don't need the graph
      def draw_graph
      end

      def get_y_labels
        [""]
      end

      def get_x_labels
        [""]
      end

      def keys
        total = 0
        max_value = 0
        @data.each {|x| total += x }
        percent_scale = 100.0 / total
        count = -1
        a = @config[:fields].collect{ |x|
          count += 1
          v = @data[count]
          perc = show_key_percent ? " "+(v * percent_scale).round.to_s+"%" : ""
          x + " [" + v.to_s + "]" + perc
        }
      end

      RADIANS = Math::PI/180

      def draw_data
        @graph = @root.add_element( "g" )
        background = @graph.add_element("g")
        midground = @graph.add_element("g")

        diameter = @graph_height > @graph_width ? @graph_width : @graph_height
        diameter -= expand_gap if expanded or expand_greatest
        diameter -= datapoint_font_size if show_data_labels
        diameter -= 10 if show_shadow
        radius = diameter / 2.0

        xoff = (width - diameter) / 2
        yoff = (height - @border_bottom - diameter)
        yoff -= 10 if show_shadow
        @graph.attributes['transform'] = "translate( #{xoff} #{yoff} )"

        wedge_text_pad = 5
        wedge_text_pad = 20 if show_percent and show_data_labels

        total = 0
        max_value = 0
        @data.each {|x| 
          max_value = max_value < x ? x : max_value
          total += x 
        }
        percent_scale = 100.0 / total

        prev_percent = 0
        rad_mult = 3.6 * RADIANS
        @config[:fields].each_index { |count|
          value = @data[count]
          percent = percent_scale * value

          radians = prev_percent * rad_mult
          x_start = radius+(Math.sin(radians) * radius)
          y_start = radius-(Math.cos(radians) * radius)
          radians = (prev_percent+percent) * rad_mult
          x_end = radius+(Math.sin(radians) * radius)
          x_end -= 0.00001 if @data.length == 1
          y_end = radius-(Math.cos(radians) * radius)
          path = "M#{radius},#{radius} L#{x_start},#{y_start} "+
            "A#{radius},#{radius} "+
            "0, #{percent >= 50 ? '1' : '0'},1, "+
            "#{x_end} #{y_end} Z"


          wedge = @foreground.add_element( "path", {
            "d" => path,
            "class" => "fill#{count+1}"
          })

          translate = nil
          tx = 0
          ty = 0
          half_percent = prev_percent + percent / 2
          radians = half_percent * rad_mult

          if show_shadow
            shadow = background.add_element( "path", {
              "d" => path,
              "filter" => "url(#dropshadow)",
              "style" => "fill: #ccc; stroke: none;"
            })
            clear = midground.add_element( "path", {
              "d" => path,
              "style" => "fill: #fff; stroke: none;"
            })
          end

          if expanded or (expand_greatest && value == max_value)
            tx = (Math.sin(radians) * expand_gap)
            ty = -(Math.cos(radians) * expand_gap)
            translate = "translate( #{tx} #{ty} )"
            wedge.attributes["transform"] = translate
            clear.attributes["transform"] = translate if clear
          end

          if show_shadow
            shadow.attributes["transform"] = 
              "translate( #{tx+shadow_offset} #{ty+shadow_offset} )"
          end
          
          if show_data_labels and value != 0
            label = ""
            label += @config[:fields][count] if show_key_data_labels
            label += " ["+value.to_s+"]" if show_actual_values
            label += " "+percent.round.to_s+"%" if show_percent

            msr = Math.sin(radians)
            mcr = Math.cos(radians)
            tx = radius + (msr * radius)
            ty = radius -(mcr * radius)

            if expanded or (expand_greatest && value == max_value)
              tx += (msr * expand_gap)
              ty -= (mcr * expand_gap)
            end
            @foreground.add_element( "text", {
              "x" => tx.to_s,
              "y" => ty.to_s,
              "class" => "dataPointLabel",
              "style" => "stroke: #fff; stroke-width: 2;"
            }).text = label.to_s
            @foreground.add_element( "text", {
              "x" => tx.to_s,
              "y" => ty.to_s,
              "class" => "dataPointLabel",
            }).text = label.to_s
          end

          prev_percent += percent
        }
      end
      

      def round val, to
        up = 10**to.to_f
        (val * up).to_i / up
      end


      def get_css
        return <<EOL
.dataPointLabel{
	fill: #000000;
	text-anchor:middle;
	font-size: #{datapoint_font_size}px;
	font-family: "Arial", sans-serif;
	font-weight: normal;
}

/* key - MUST match fill styles */
.key1,.fill1{
	fill: #ff0000;
	fill-opacity: 0.7;
	stroke: none;
	stroke-width: 1px;	
}
.key2,.fill2{
	fill: #0000ff;
	fill-opacity: 0.7;
	stroke: none;
	stroke-width: 1px;	
}
.key3,.fill3{
	fill-opacity: 0.7;
	fill: #00ff00;
	stroke: none;
	stroke-width: 1px;	
}
.key4,.fill4{
	fill-opacity: 0.7;
	fill: #ffcc00;
	stroke: none;
	stroke-width: 1px;	
}
.key5,.fill5{
	fill-opacity: 0.7;
	fill: #00ccff;
	stroke: none;
	stroke-width: 1px;	
}
.key6,.fill6{
	fill-opacity: 0.7;
	fill: #ff00ff;
	stroke: none;
	stroke-width: 1px;	
}
.key7,.fill7{
	fill-opacity: 0.7;
	fill: #00ff99;
	stroke: none;
	stroke-width: 1px;	
}
.key8,.fill8{
	fill-opacity: 0.7;
	fill: #ffff00;
	stroke: none;
	stroke-width: 1px;	
}
.key9,.fill9{
	fill-opacity: 0.7;
	fill: #cc6666;
	stroke: none;
	stroke-width: 1px;	
}
.key10,.fill10{
	fill-opacity: 0.7;
	fill: #663399;
	stroke: none;
	stroke-width: 1px;	
}
.key11,.fill11{
	fill-opacity: 0.7;
	fill: #339900;
	stroke: none;
	stroke-width: 1px;	
}
.key12,.fill12{
	fill-opacity: 0.7;
	fill: #9966FF;
	stroke: none;
	stroke-width: 1px;	
}
EOL
      end
    end
  end
end
