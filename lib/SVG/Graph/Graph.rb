begin
  require 'zlib'
  @@__have_zlib = true
rescue
  @@__have_zlib = false
end

require 'rexml/document'

module SVG
  module Graph
    VERSION = '@ANT_VERSION@'

    # === Base object for generating SVG Graphs
    # 
    # == Synopsis
    #
    # This class is only used as a superclass of specialized charts.  Do not
    # attempt to use this class directly, unless creating a new chart type.
    #
    # For examples of how to subclass this class, see the existing specific
    # subclasses, such as SVG::Graph::Pie.
    #
    # == Examples
    #
    # For examples of how to use this package, see either the test files, or
    # the documentation for the specific class you want to use.
    #
    # * file:test/plot.rb
    # * file:test/single.rb
    # * file:test/test.rb
    # * file:test/timeseries.rb
    # 
    # == Description
    # 
    # This package should be used as a base for creating SVG graphs.
    #
    # == Acknowledgements
    #
    # Leo Lapworth for creating the SVG::TT::Graph package which this Ruby
    # port is based on.
    #
    # Stephen Morgan for creating the TT template and SVG.
    # 
    # == See
    #
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
    class Graph
      include REXML

      # Initialize the graph object with the graph settings.  You won't
      # instantiate this class directly; see the subclass for options.
      # [width] 500
      # [height] 300
      # [show_x_guidelines] false
      # [show_y_guidelines] true
      # [show_data_values] true
      # [min_scale_value] 0
      # [show_x_labels] true
      # [stagger_x_labels] false
      # [rotate_x_labels] false
      # [step_x_labels] 1
      # [step_include_first_x_label] true
      # [show_y_labels] true
      # [rotate_y_labels] false
      # [scale_integers] false
      # [show_x_title] false
      # [x_title] 'X Field names'
      # [show_y_title] false
      # [y_title_text_direction] :bt
      # [y_title] 'Y Scale'
      # [show_graph_title] false
      # [graph_title] 'Graph Title'
      # [show_graph_subtitle] false
      # [graph_subtitle] 'Graph Sub Title'
      # [key] true,
      # [key_position] :right, # bottom or righ
      # [font_size] 12
      # [title_font_size] 16
      # [subtitle_font_size] 14
      # [x_label_font_size] 12
      # [x_title_font_size] 14
      # [y_label_font_size] 12
      # [y_title_font_size] 14
      # [key_font_size] 10
      # [no_css] false
      # [add_popups] false
      def initialize( config )
        @config = config

        self.top_align = self.top_font = self.right_align = self.right_font = 0

        init_with({
          :width                => 500,
          :height                => 300,
          :show_x_guidelines    => false,
          :show_y_guidelines    => true,
          :show_data_values     => true,

#          :min_scale_value      => 0,

          :show_x_labels        => true,
          :stagger_x_labels     => false,
          :rotate_x_labels      => false,
          :step_x_labels        => 1,
          :step_include_first_x_label => true,

          :show_y_labels        => true,
          :rotate_y_labels      => false,
          :stagger_y_labels     => false,
          :scale_integers       => false,

          :show_x_title         => false,
          :x_title              => 'X Field names',

          :show_y_title         => false,
          :y_title_text_direction => :bt,
          :y_title              => 'Y Scale',

          :show_graph_title      => false,
          :graph_title          => 'Graph Title',
          :show_graph_subtitle  => false,
          :graph_subtitle        => 'Graph Sub Title',
          :key                  => true, 
          :key_position          => :right, # bottom or right

          :font_size            =>12,
          :title_font_size      =>16,
          :subtitle_font_size   =>14,
          :x_label_font_size    =>12,
          :x_title_font_size    =>14,
          :y_label_font_size    =>12,
          :y_title_font_size    =>14,
          :key_font_size        =>10,
          
          :no_css               =>false,
          :add_popups           =>false,
        })

				set_defaults if respond_to? :set_defaults

        init_with config
      end

      
      # This method allows you do add data to the graph object.
      # It can be called several times to add more data sets in.
      #
      #   data_sales_02 = [12, 45, 21];
      #   
      #   graph.add_data({
      #     :data => data_sales_02,
      #     :title => 'Sales 2002'
      #   })
      def add_data conf
        @data = [] unless defined? @data

        if conf[:data] and conf[:data].kind_of? Array
          @data << conf
        else
          raise "No data provided by #{conf.inspect}"
        end
      end


      # This method removes all data from the object so that you can
      # reuse it to create a new graph but with the same config options.
      #
      #   graph.clear_data
      def clear_data 
        @data = []
      end


      # This method processes the template with the data and
      # config which has been set and returns the resulting SVG.
      #
      # This method will croak unless at least one data set has
      # been added to the graph object.
      #
      #   print graph.burn
      def burn
        raise "No data available" unless @data.size > 0
        
        calculations if respond_to? :calculations

        start_svg
        calculate_graph_dimensions
        @foreground = Element.new( "g" )
        draw_graph
        draw_titles
        draw_legend
        draw_data
        @graph.add_element( @foreground )
        style

        data = ""
        @doc.write( data, 0 )

        if @config[:compress]
          if @@__have_zlib
            inp, out = IO.pipe
            gz = Zlib::GzipWriter.new( out )
            gz.write data
            gz.close
            data = inp.read
          else
            data << "<!-- Ruby Zlib not available for SVGZ -->";
          end
        end
        
        return data
      end


      #   Set the height of the graph box, this is the total height
      #   of the SVG box created - not the graph it self which auto
      #   scales to fix the space.
      attr_accessor :height
      #   Set the width of the graph box, this is the total width
      #   of the SVG box created - not the graph it self which auto
      #   scales to fix the space.
      attr_accessor :width
      #   Set the path to an external stylesheet, set to '' if
      #   you want to revert back to using the defaut internal version.
      #
      #   To create an external stylesheet create a graph using the
      #   default internal version and copy the stylesheet section to
      #   an external file and edit from there.
      attr_accessor :style_sheet
      #   (Bool) Show the value of each element of data on the graph
      attr_accessor :show_data_values
      #   The point at which the Y axis starts, defaults to '0',
      #   if set to nil it will default to the minimum data value.
      attr_accessor :min_scale_value
      #   Whether to show labels on the X axis or not, defaults
      #   to true, set to false if you want to turn them off.
      attr_accessor :show_x_labels
      #   This puts the X labels at alternative levels so if they
      #   are long field names they will not overlap so easily.
      #   Default it false, to turn on set to true.
      attr_accessor :stagger_x_labels
      #   This puts the Y labels at alternative levels so if they
      #   are long field names they will not overlap so easily.
      #   Default it false, to turn on set to true.
      attr_accessor :stagger_y_labels
      #   This turns the X axis labels by 90 degrees.
      #   Default it false, to turn on set to true.
      attr_accessor :rotate_x_labels
      #   This turns the Y axis labels by 90 degrees.
      #   Default it false, to turn on set to true.
      attr_accessor :rotate_y_labels
      #   How many "steps" to use between displayed X axis labels,
      #   a step of one means display every label, a step of two results
      #   in every other label being displayed (label <gap> label <gap> label),
      #   a step of three results in every third label being displayed
      #   (label <gap> <gap> label <gap> <gap> label) and so on.
      attr_accessor :step_x_labels
      #   Whether to (when taking "steps" between X axis labels) step from 
      #   the first label (i.e. always include the first label) or step from
      #   the X axis origin (i.e. start with a gap if step_x_labels is greater
      #   than one).
      attr_accessor :step_include_first_x_label
      #   Whether to show labels on the Y axis or not, defaults
      #   to true, set to false if you want to turn them off.
      attr_accessor :show_y_labels
      #   Ensures only whole numbers are used as the scale divisions.
      #   Default it false, to turn on set to true. This has no effect if 
      #   scale divisions are less than 1.
      attr_accessor :scale_integers
      #   This defines the gap between markers on the Y axis,
      #   default is a 10th of the max_value, e.g. you will have
      #   10 markers on the Y axis. NOTE: do not set this too
      #   low - you are limited to 999 markers, after that the
      #   graph won't generate.
      attr_accessor :scale_divisions
      #   Whether to show the title under the X axis labels,
      #   default is false, set to true to show.
      attr_accessor :show_x_title
      #   What the title under X axis should be, e.g. 'Months'.
      attr_accessor :x_title
      #   Whether to show the title under the Y axis labels,
      #   default is false, set to true to show.
      attr_accessor :show_y_title
      #   Aligns writing mode for Y axis label. 
      #   Defaults to :bt (Bottom to Top).
      #   Change to :tb (Top to Bottom) to reverse.
      attr_accessor :y_title_text_direction
      #   What the title under Y axis should be, e.g. 'Sales in thousands'.
      attr_accessor :y_title
      #   Whether to show a title on the graph, defaults
      #   to false, set to true to show.
      attr_accessor :show_graph_title
      #   What the title on the graph should be.
      attr_accessor :graph_title
      #   Whether to show a subtitle on the graph, defaults
      #   to false, set to true to show.
      attr_accessor :show_graph_subtitle
      #   What the subtitle on the graph should be.
      attr_accessor :graph_subtitle
      #   Whether to show a key, defaults to false, set to
      #   true if you want to show it.
      attr_accessor :key
      #   Where the key should be positioned, defaults to
      #   :right, set to :bottom if you want to move it.
      attr_accessor :key_position
      # Set the font size (in points) of the data point labels
      attr_accessor :font_size
      # Set the font size of the X axis labels
      attr_accessor :x_label_font_size
      # Set the font size of the X axis title
      attr_accessor :x_title_font_size
      # Set the font size of the Y axis labels
      attr_accessor :y_label_font_size
      # Set the font size of the Y axis title
      attr_accessor :y_title_font_size
      # Set the title font size
      attr_accessor :title_font_size
      # Set the subtitle font size
      attr_accessor :subtitle_font_size
      # Set the key font size
      attr_accessor :key_font_size
      # Show guidelines for the X axis
      attr_accessor :show_x_guidelines
      # Show guidelines for the Y axis
      attr_accessor :show_y_guidelines
      # Do not use CSS if set to true.  Many SVG viewers do not support CSS, but
      # not using CSS can result in larger SVGs as well as making it impossible to
      # change colors after the chart is generated.  Defaults to false.
      attr_accessor :no_css
      # Add popups for the data points on some graphs
      attr_accessor :add_popups


      protected

      def sort( *arrys )
        sort_multiple( arrys )
      end

      # Overwrite configuration options with supplied options.  Used
      # by subclasses.
      def init_with config
        config.each { |key, value|
          self.send((key.to_s+"=").to_sym, value ) if respond_to? key.to_sym
        }
      end

      attr_accessor :top_align, :top_font, :right_align, :right_font

      KEY_BOX_SIZE = 12

      # Override this (and call super) to change the margin to the left
      # of the plot area.  Results in @border_left being set.
      def calculate_left_margin
        @border_left = 7
        # Check for Y labels
        max_y_label_height_px = rotate_y_labels ? 
          y_label_font_size :
          get_y_labels.max{|a,b| 
            a.to_s.length<=>b.to_s.length
          }.to_s.length * y_label_font_size * 0.6
        @border_left += max_y_label_height_px if show_y_labels
        @border_left += max_y_label_height_px + 10 if stagger_y_labels
        @border_left += y_title_font_size + 5 if show_y_title
      end


      # Calculates the width of the widest Y label.  This will be the
      # character height if the Y labels are rotated
      def max_y_label_width_px
        return font_size if rotate_y_labels
      end


      # Override this (and call super) to change the margin to the right
      # of the plot area.  Results in @border_right being set.
      def calculate_right_margin
        @border_right = 7
        if key and key_position == :right
          val = keys.max { |a,b| a.length <=> b.length }
          @border_right += val.length * key_font_size * 0.6 
          @border_right += KEY_BOX_SIZE
          @border_right += 10    # Some padding around the box
        end
      end


      # Override this (and call super) to change the margin to the top
      # of the plot area.  Results in @border_top being set.
      def calculate_top_margin
        @border_top = 5
        @border_top += title_font_size if show_graph_title
        @border_top += 5
        @border_top += subtitle_font_size if show_graph_subtitle
      end


      # Adds pop-up point information to a graph.
      def add_popup( x, y, label )
        txt_width = label.length * font_size * 0.6 + 10
        tx = (x+txt_width > width ? x-5 : x+5)
        t = @foreground.add_element( "text", {
          "x" => tx.to_s,
          "y" => (y - font_size).to_s,
          "visibility" => "hidden",
        })
        t.attributes["style"] = "fill: #000; "+
          (x+txt_width > width ? "text-anchor: end;" : "text-anchor: start;")
        t.text = label.to_s
        t.attributes["id"] = t.object_id.to_s

        @foreground.add_element( "circle", {
          "cx" => x.to_s,
          "cy" => y.to_s,
          "r" => "10",
          "style" => "opacity: 0",
          "onmouseover" => 
            "document.getElementById(#{t.object_id}).setAttribute('visibility', 'visible' )",
          "onmouseout" => 
            "document.getElementById(#{t.object_id}).setAttribute('visibility', 'hidden' )",
        })

      end

      
      # Override this (and call super) to change the margin to the bottom
      # of the plot area.  Results in @border_bottom being set.
      def calculate_bottom_margin
        @border_bottom = 7
        if key and key_position == :bottom
          @border_bottom += @data.size * (font_size + 5)
          @border_bottom += 10
        end
        if show_x_labels
		  max_x_label_height_px = (not rotate_x_labels) ? 
            x_label_font_size :
            get_x_labels.max{|a,b| 
              a.to_s.length<=>b.to_s.length
            }.to_s.length * x_label_font_size * 0.6
          @border_bottom += max_x_label_height_px
          @border_bottom += max_x_label_height_px + 10 if stagger_x_labels
        end
        @border_bottom += x_title_font_size + 5 if show_x_title
      end


      # Draws the background, axis, and labels.
      def draw_graph
        @graph = @root.add_element( "g", {
          "transform" => "translate( #@border_left #@border_top )"
        })

        # Background
        @graph.add_element( "rect", {
          "x" => "0",
          "y" => "0",
          "width" => @graph_width.to_s,
          "height" => @graph_height.to_s,
          "class" => "graphBackground"
        })

        # Axis
        @graph.add_element( "path", {
          "d" => "M 0 0 v#@graph_height",
          "class" => "axis",
          "id" => "xAxis"
        })
        @graph.add_element( "path", {
          "d" => "M 0 #@graph_height h#@graph_width",
          "class" => "axis",
          "id" => "yAxis"
        })

        draw_x_labels
        draw_y_labels
      end


      # Where in the X area the label is drawn
      # Centered in the field, should be width/2.  Start, 0.
      def x_label_offset( width )
        0
      end

      def make_datapoint_text( x, y, value, style="" )
        if show_data_values
          @foreground.add_element( "text", {
            "x" => x.to_s,
            "y" => y.to_s,
            "class" => "dataPointLabel",
            "style" => "#{style} stroke: #fff; stroke-width: 2;"
          }).text = value.to_s
          text = @foreground.add_element( "text", {
            "x" => x.to_s,
            "y" => y.to_s,
            "class" => "dataPointLabel"
          })
          text.text = value.to_s
          text.attributes["style"] = style if style.length > 0
        end
      end


      # Draws the X axis labels
      def draw_x_labels
        stagger = x_label_font_size + 5
        if show_x_labels
          label_width = field_width

          count = 0
          for label in get_x_labels
            if step_include_first_x_label == true then
              step = count % step_x_labels
            else
              step = (count + 1) % step_x_labels
            end

            if step == 0 then
              text = @graph.add_element( "text" )
              text.attributes["class"] = "xAxisLabels"
              text.text = label.to_s

              x = count * label_width + x_label_offset( label_width )
              y = @graph_height + x_label_font_size + 3
              t = 0 - (font_size / 2)

              if stagger_x_labels and count % 2 == 1
                y += stagger
                @graph.add_element( "path", {
                  "d" => "M#{x} #@graph_height v#{stagger}",
                  "class" => "staggerGuideLine"
                })
              end

              text.attributes["x"] = x.to_s
              text.attributes["y"] = y.to_s
              if rotate_x_labels
                text.attributes["transform"] = 
                  "rotate( 90 #{x} #{y-x_label_font_size} )"+
                  " translate( 0 -#{x_label_font_size/4} )"
                text.attributes["style"] = "text-anchor: start"
              else
                text.attributes["style"] = "text-anchor: middle"
              end
            end

            draw_x_guidelines( label_width, count ) if show_x_guidelines
            count += 1
          end
        end
      end


      # Where in the Y area the label is drawn
      # Centered in the field, should be width/2.  Start, 0.
      def y_label_offset( height )
        0
      end


      def field_width
        (@graph_width.to_f - font_size*2*right_font) /
           (get_x_labels.length - right_align)
      end


      def field_height
        (@graph_height.to_f - font_size*2*top_font) /
           (get_y_labels.length - top_align)
      end


      # Draws the Y axis labels
      def draw_y_labels
        stagger = y_label_font_size + 5
        if show_y_labels
          label_height = field_height

          count = 0
          y_offset = @graph_height + y_label_offset( label_height )
          y_offset += font_size/1.2 unless rotate_y_labels
          for label in get_y_labels
            y = y_offset - (label_height * count)
            x = rotate_y_labels ? 0 : -3

            if stagger_y_labels and count % 2 == 1
              x -= stagger
              @graph.add_element( "path", {
                "d" => "M#{x} #{y} h#{stagger}",
                "class" => "staggerGuideLine"
              })
            end

            text = @graph.add_element( "text", {
              "x" => x.to_s,
              "y" => y.to_s,
              "class" => "yAxisLabels"
            })
            text.text = label.to_s
            if rotate_y_labels
              text.attributes["transform"] = "translate( -#{font_size} 0 ) "+
                "rotate( 90 #{x} #{y} ) "
              text.attributes["style"] = "text-anchor: middle"
            else
              text.attributes["y"] = (y - (y_label_font_size/2)).to_s
              text.attributes["style"] = "text-anchor: end"
            end
            draw_y_guidelines( label_height, count ) if show_y_guidelines
            count += 1
          end
        end
      end


      # Draws the X axis guidelines
      def draw_x_guidelines( label_height, count )
        if count != 0
          @graph.add_element( "path", {
            "d" => "M#{label_height*count} 0 v#@graph_height",
            "class" => "guideLines"
          })
        end
      end


      # Draws the Y axis guidelines
      def draw_y_guidelines( label_height, count )
        if count != 0
          @graph.add_element( "path", {
            "d" => "M0 #{@graph_height-(label_height*count)} h#@graph_width",
            "class" => "guideLines"
          })
        end
      end


      # Draws the graph title and subtitle
      def draw_titles
        if show_graph_title
          @root.add_element( "text", {
            "x" => (width / 2).to_s,
            "y" => (title_font_size).to_s,
            "class" => "mainTitle"
          }).text = graph_title.to_s
        end

        if show_graph_subtitle
          y_subtitle = show_graph_title ? 
            title_font_size + 10 :
            subtitle_font_size
          @root.add_element("text", {
            "x" => (width / 2).to_s,
            "y" => (y_subtitle).to_s,
            "class" => "subTitle"
          }).text = graph_subtitle.to_s
        end

        if show_x_title
          y = @graph_height + @border_top + x_title_font_size
          if show_x_labels
            y += x_label_font_size + 5 if stagger_x_labels
            y += x_label_font_size + 5
          end
          x = width / 2

          @root.add_element("text", {
            "x" => x.to_s,
            "y" => y.to_s,
            "class" => "xAxisTitle",
          }).text = x_title.to_s
        end

        if show_y_title
          x = y_title_font_size + (y_title_text_direction==:bt ? 3 : -3)
          y = height / 2

          text = @root.add_element("text", {
            "x" => x.to_s,
            "y" => y.to_s,
            "class" => "yAxisTitle",
          })
          text.text = y_title.to_s
          if y_title_text_direction == :bt
            text.attributes["transform"] = "rotate( -90, #{x}, #{y} )"
          else
            text.attributes["transform"] = "rotate( 90, #{x}, #{y} )"
          end
        end
      end

      def keys 
        return @data.collect{ |d| d[:title] }
      end

      # Draws the legend on the graph
      def draw_legend
        if key
          group = @root.add_element( "g" )

          key_count = 0
          for key_name in keys
            y_offset = (KEY_BOX_SIZE * key_count) + (key_count * 5)
            group.add_element( "rect", {
              "x" => 0.to_s,
              "y" => y_offset.to_s,
              "width" => KEY_BOX_SIZE.to_s,
              "height" => KEY_BOX_SIZE.to_s,
              "class" => "key#{key_count+1}"
            })
            group.add_element( "text", {
              "x" => (KEY_BOX_SIZE + 5).to_s,
              "y" => (y_offset + KEY_BOX_SIZE).to_s,
              "class" => "keyText"
            }).text = key_name.to_s
            key_count += 1
          end

          case key_position
          when :right
            x_offset = @graph_width + @border_left + 10
            y_offset = @border_top + 20
          when :bottom
            x_offset = @border_left + 20
            y_offset = @border_top + @graph_height + 5
            if show_x_labels
			  max_x_label_height_px = (not rotate_x_labels) ? 
				x_label_font_size :
				get_x_labels.max{|a,b| 
				  a.to_s.length<=>b.to_s.length
				}.to_s.length * x_label_font_size * 0.6
                x_label_font_size
              y_offset += max_x_label_height_px
              y_offset += max_x_label_height_px + 5 if stagger_x_labels
            end
            y_offset += x_title_font_size + 5 if show_x_title
          end
          group.attributes["transform"] = "translate(#{x_offset} #{y_offset})"
        end
      end


      private

      def sort_multiple( arrys, lo=0, hi=arrys[0].length-1 )
        if lo < hi
          p = partition(arrys,lo,hi)
          sort_multiple(arrys, lo, p-1)
          sort_multiple(arrys, p+1, hi)
        end
        arrys 
      end

      def partition( arrys, lo, hi )
        p = arrys[0][lo]
        l = lo
        z = lo+1
        while z <= hi
          if arrys[0][z] < p
            l += 1
            arrys.each { |arry| arry[z], arry[l] = arry[l], arry[z] }
          end
          z += 1
        end
        arrys.each { |arry| arry[lo], arry[l] = arry[l], arry[lo] }
        l
      end

      def style
        if no_css
          styles = parse_css
          @root.elements.each("//*[@class]") { |el|
            cl = el.attributes["class"]
            style = styles[cl]
            style += el.attributes["style"] if el.attributes["style"]
            el.attributes["style"] = style
          }
        end
      end

      def parse_css
        css = get_style
        rv = {}
        while css =~ /^(\.(\w+)(?:\s*,\s*\.\w+)*)\s*\{/m
          names_orig = names = $1
          css = $'
          css =~ /([^}]+)\}/m
          content = $1
          css = $'

          nms = []
          while names =~ /^\s*,?\s*\.(\w+)/
            nms << $1
            names = $'
          end

          content = content.tr( "\n\t", " ")
          for name in nms
            current = rv[name]
            current = current ? current+"; "+content : content
            rv[name] = current.strip.squeeze(" ")
          end
        end
        return rv
      end


      # Override and place code to add defs here
      def add_defs defs
      end


      def start_svg
        # Base document
        @doc = Document.new
        @doc << XMLDecl.new
        @doc << DocType.new( %q{svg PUBLIC "-//W3C//DTD SVG 1.0//EN" } +
          %q{"http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd"} )
        if style_sheet && style_sheet != ''
          @doc << Instruction.new( "xml-stylesheet",
            %Q{href="#{style_sheet}" type="text/css"} )
        end
        @root = @doc.add_element( "svg", {
          "width" => width.to_s,
          "height" => height.to_s,
          "viewBox" => "0 0 #{width} #{height}",
          "xmlns" => "http://www.w3.org/2000/svg",
          "xmlns:xlink" => "http://www.w3.org/1999/xlink",
          "xmlns:a3" => "http://ns.adobe.com/AdobeSVGViewerExtensions/3.0/",
          "a3:scriptImplementation" => "Adobe"
        })
        @root << Comment.new( " "+"\\"*66 )
        @root << Comment.new( " Created with SVG::Graph " )
        @root << Comment.new( " SVG::Graph by Sean E. Russell " )
        @root << Comment.new( " Losely based on SVG::TT::Graph for Perl by"+
        " Leo Lapworth & Stephan Morgan " )
        @root << Comment.new( " "+"/"*66 )

        defs = @root.add_element( "defs" )
        add_defs defs
        if not(style_sheet && style_sheet != '') and !no_css
          @root << Comment.new(" include default stylesheet if none specified ")
          style = defs.add_element( "style", {"type"=>"text/css"} )
          style << CData.new( get_style )
        end

        @root << Comment.new( "SVG Background" )
        @root.add_element( "rect", {
          "width" => width.to_s,
          "height" => height.to_s,
          "x" => "0",
          "y" => "0",
          "class" => "svgBackground"
        })
      end


      def calculate_graph_dimensions
        calculate_left_margin
        calculate_right_margin
        calculate_bottom_margin
        calculate_top_margin
        @graph_width = width - @border_left - @border_right
        @graph_height = height - @border_top - @border_bottom
      end

      def get_style
        return <<EOL
/* Copy from here for external style sheet */
.svgBackground{
  fill:#ffffff;
}
.graphBackground{
  fill:#f0f0f0;
}

/* graphs titles */
.mainTitle{
  text-anchor: middle;
  fill: #000000;
  font-size: #{title_font_size}px;
  font-family: "Arial", sans-serif;
  font-weight: normal;
}
.subTitle{
  text-anchor: middle;
  fill: #999999;
  font-size: #{subtitle_font_size}px;
  font-family: "Arial", sans-serif;
  font-weight: normal;
}

.axis{
  stroke: #000000;
  stroke-width: 1px;
}

.guideLines{
  stroke: #666666;
  stroke-width: 1px;
  stroke-dasharray: 5 5;
}

.xAxisLabels{
  text-anchor: middle;
  fill: #000000;
  font-size: #{x_label_font_size}px;
  font-family: "Arial", sans-serif;
  font-weight: normal;
}

.yAxisLabels{
  text-anchor: end;
  fill: #000000;
  font-size: #{y_label_font_size}px;
  font-family: "Arial", sans-serif;
  font-weight: normal;
}

.xAxisTitle{
  text-anchor: middle;
  fill: #ff0000;
  font-size: #{x_title_font_size}px;
  font-family: "Arial", sans-serif;
  font-weight: normal;
}

.yAxisTitle{
  fill: #ff0000;
  text-anchor: middle;
  font-size: #{y_title_font_size}px;
  font-family: "Arial", sans-serif;
  font-weight: normal;
}

.dataPointLabel{
  fill: #000000;
  text-anchor:middle;
  font-size: 10px;
  font-family: "Arial", sans-serif;
  font-weight: normal;
}

.staggerGuideLine{
  fill: none;
  stroke: #000000;
  stroke-width: 0.5px;  
}

#{get_css}

.keyText{
  fill: #000000;
  text-anchor:start;
  font-size: #{key_font_size}px;
  font-family: "Arial", sans-serif;
  font-weight: normal;
}
/* End copy for external style sheet */
EOL
      end

    end
  end
end
