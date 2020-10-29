begin
  require 'zlib'
rescue
  # No Zlib.
end

require 'rexml/document'

module SVG
  module Graph

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
      # [x_axis_position] nil
      # [y_axis_position] nil
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
      # [x_title_location] :middle | :end
      # [show_y_title] false
      # [y_title_text_direction] :bt | :tb
      # [y_title] 'Y Scale'
      # [y_title_location] :middle | :end
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
      # [number_format] '%.2f'
      def initialize( config )
        @config = config
        @data = []
        #self.top_align = self.top_font = 0
        #self.right_align = self.right_font = 0

        init_with({
          :width                => 500,
          :height               => 300,
          :show_x_guidelines    => false,
          :show_y_guidelines    => true,
          :show_data_values     => true,

          :x_axis_position      => nil,
          :y_axis_position      => nil,

          :min_scale_value      => nil,

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
          :x_title_location     => :middle,  # or :end

          :show_y_title         => false,
          :y_title_text_direction => :bt,  # other option is :tb
          :y_title              => 'Y Scale',
          :y_title_location     => :middle,  # or :end

          :show_graph_title      => false,
          :graph_title          => 'Graph Title',
          :show_graph_subtitle  => false,
          :graph_subtitle        => 'Graph Sub Title',
          :key                  => true,
          :key_width             => nil,
          :key_position          => :right, # bottom or right

          :font_size            => 12,
          :title_font_size      => 16,
          :subtitle_font_size   => 14,
          :x_label_font_size    => 12,
          :y_label_font_size    => 12,
          :x_title_font_size    => 14,
          :y_title_font_size    => 14,
          :key_font_size        => 10,
          :key_box_size         => 12,
          :key_spacing          => 5,

          :no_css               => false,
          :add_popups           => false,
          :popup_radius         => 10,
          :number_format        => '%.2f',
          :style_sheet          => '',
          :inline_style_sheet   => ''
        })
        set_defaults if self.respond_to? :set_defaults
        # override default values with user supplied values
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
        @data = [] unless (defined? @data and !@data.nil?)

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
      #
      def burn
        raise "No data available" unless @data.size > 0

        start_svg
        calculate_graph_dimensions
        @foreground = Element.new( "g" )
        draw_graph
        draw_titles
        draw_legend
        draw_data  # this method needs to be implemented by child classes
        @graph.add_element( @foreground )
        style

        data = ""
        @doc.write( data, 0 )

        if @config[:compress]
          if defined?(Zlib)
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

      # Burns the graph but returns only the <svg> node as String without the
      # Doctype and XML Declaration. This allows easy integration into
      # existing xml documents.
      #
      # @return [String] the SVG node which represents the Graph
      def burn_svg_only
        # initialize all instance variables by burning the graph
        burn
        f = REXML::Formatters::Pretty.new(0)
        f.compact = true
        out = ''
        f.write(@root, out)
        return out
      end

      # Burns the graph to an SVG string and returns it with a text/html mime type to be
      # displayed in IRuby.
      #
      # @return [Array] A 2-dimension array containing the SVg string and a mime-type. This is the format expected by IRuby.
      def to_iruby
        ["text/html", burn_svg_only]
      end


      #   Set the height of the graph box, this is the total height
      #   of the SVG box created - not the graph it self which auto
      #   scales to fix the space.
      attr_accessor :height
      #   Set the width of the graph box, this is the total width
      #   of the SVG box created - not the graph it self which auto
      #   scales to fix the space.
      attr_accessor :width
      #   Set the path/url to an external stylesheet, set to '' if
      #   you want to revert back to using the defaut internal version.
      #
      #   To create an external stylesheet create a graph using the
      #   default internal version and copy the stylesheet section to
      #   an external file and edit from there.
      attr_accessor :style_sheet
      #   Define as String the stylesheet contents to be inlined, set to '' to disable.
      #   This can be used, when referring to a url via :style_sheet is not suitable.
      #   E.g. in situations where there will be no internet access or the graph must
      #   consist of only one file.
      #
      #   If not empty, the :style_sheet parameter (url) above will be ignored and is
      #   not written to the file
      #   see also https://github.com/erullmann/svg-graph2/commit/55eb6e983f6fcc69cc5a110d0ee6e05f906f639a
      #   Default: ''
      attr_accessor :inline_style_sheet
      #   (Bool) Show the value of each element of data on the graph
      attr_accessor :show_data_values
      #   By default (nil/undefined) the x-axis is at the bottom of the graph.
      #   With this property a custom position for the x-axis can be defined.
      #   Valid values are between :min_scale_value and maximum value of the
      #   data.
      #   Default: nil
      attr_accessor :x_axis_position
      #   By default (nil/undefined) the y-axis is the left border of the graph.
      #   With this property a custom position for the y-axis can be defined.
      #   Valid values are any values in the range of x-values (in case of a
      #   Plot) or any of the :fields values (in case of Line/Bar Graphs, note
      #   the '==' operator is used to find at which value to draw the axis).
      #   Default: nil
      attr_accessor :y_axis_position
      #   The point at which the Y axis starts, defaults to nil,
      #   if set to nil it will default to the minimum data value.
      attr_accessor :min_scale_value
      #   Whether to show labels on the X axis or not, defaults
      #   to true, set to false if you want to turn them off.
      attr_accessor :show_x_labels
      #   This puts the X labels at alternative levels so if they
      #   are long field names they will not overlap so easily.
      #   Default is false, to turn on set to true.
      attr_accessor :stagger_x_labels
      #   This puts the Y labels at alternative levels so if they
      #   are long field names they will not overlap so easily.
      #   Default is false, to turn on set to true.
      attr_accessor :stagger_y_labels
      #   This turns the X axis labels by 90 degrees when true or by a custom
      #   amount when a numeric value is given.
      #   Default is false, to turn on set to true.
      attr_accessor :rotate_x_labels
      #   This turns the Y axis labels by 90 degrees when true or by a custom
      #   amount when a numeric value is given.
      #   Default is true, to turn on set to false.
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
      #   Default is false, to turn on set to true. This has no effect if
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
      #   Where the x_title should be positioned, either in the :middle of the axis or
      #   at the :end of the axis. Defaults to :middle
      attr_accessor :x_title_location
      #   Whether to show the title under the Y axis labels,
      #   default is false, set to true to show.
      attr_accessor :show_y_title
      #   Aligns writing mode for Y axis label.
      #   Defaults to :bt (Bottom to Top).
      #   Change to :tb (Top to Bottom) to reverse.
      attr_accessor :y_title_text_direction
      #   What the title under Y axis should be, e.g. 'Sales in thousands'.
      attr_accessor :y_title
      #   Where the y_title should be positioned, either in the :middle of the axis or
      #   at the :end of the axis. Defaults to :middle
      attr_accessor :y_title_location
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
      #   Whether to show a key (legend), defaults to true, set to
      #   false if you want to hide it.
      attr_accessor :key
      #   Where the key should be positioned, defaults to
      #   :right, set to :bottom if you want to move it.
      attr_accessor :key_position

      attr_accessor :key_box_size

      attr_accessor :key_spacing

      attr_accessor :key_width

      # Set the font size (in points) of the data point labels.
      # Defaults to 12.
      attr_accessor :font_size
      # Set the font size of the X axis labels.
      # Defaults to 12.
      attr_accessor :x_label_font_size
      # Set the font size of the X axis title.
      # Defaults to 14.
      attr_accessor :x_title_font_size
      # Set the font size of the Y axis labels.
      # Defaults to 12.
      attr_accessor :y_label_font_size
      # Set the font size of the Y axis title.
      # Defaults to 14.
      attr_accessor :y_title_font_size
      # Set the title font size.
      # Defaults to 16.
      attr_accessor :title_font_size
      # Set the subtitle font size.
      # Defaults to 14.
      attr_accessor :subtitle_font_size
      # Set the key font size.
      # Defaults to 10.
      attr_accessor :key_font_size
      # Show guidelines for the X axis, default is false
      attr_accessor :show_x_guidelines
      # Show guidelines for the Y axis, default is true
      attr_accessor :show_y_guidelines
      # Do not use CSS if set to true.  Many SVG viewers do not support CSS, but
      # not using CSS can result in larger SVGs as well as making it impossible to
      # change colors after the chart is generated.  Defaults to false.
      attr_accessor :no_css
      # Add popups for the data points on some graphs, default is false.
      attr_accessor :add_popups
      # Customize popup radius
      attr_accessor :popup_radius
      # Number format values and Y axis representation like 1.2345667 represent as 1.23,
      # Any valid format accepted by sprintf can be specified.
      # If you don't want to change the format in any way you can use "%s". Defaults to "%.2f"
      attr_accessor :number_format


      protected

      # implementation of quicksort
      # used for Schedule and Plot
      def sort( *arrys )
        sort_multiple( arrys )
      end

      # Overwrite configuration options with supplied options.  Used
      # by subclasses.
      def init_with config
        config.each { |key, value|
            self.send( key.to_s+"=", value ) if self.respond_to?  key
        }
      end

      # Override this (and call super) to change the margin to the left
      # of the plot area.  Results in @border_left being set.
      #
      # By default it is 7 + max label height(font size or string length, depending on rotate) + title height
      def calculate_left_margin
        @border_left = 7
        # Check size of Y labels
        @border_left += max_y_label_width_px
        if (show_y_title && (y_title_location ==:middle))
          @border_left += y_title_font_size + 5
        end
      end

      # Calculates the width of the widest Y label.  This will be the
      # character height if the Y labels are rotated. Returns 0 if labels
      # are not shown
      def max_y_label_width_px
        return 0 if !show_y_labels
        if !rotate_y_labels
          max_width = get_longest_label(get_y_labels).to_s.length * y_label_font_size * 0.6
        else
          max_width = y_label_font_size + 3
        end
        max_width += 5 + y_label_font_size if stagger_y_labels
        return max_width
      end


      # Override this (and call super) to change the margin to the right
      # of the plot area.  Results in @border_right being set.
      #
      # By default it is 7 + width of the key if it is placed on the right
      #   or the maximum of this value or the tilte length (if title is placed at :end)
      def calculate_right_margin
        @border_right = 7
        if key and key_position == :right
          val = keys.max { |a,b| a.length <=> b.length }
          @border_right += val.length * key_font_size * 0.6
          @border_right += key_box_size
          @border_right += 10    # Some padding around the box

          if key_width.nil?
            @border_right
          else
            @border_right = [key_width, @border_right].min
          end
        end
        if (x_title_location == :end)
          @border_right = [@border_right, x_title.length * x_title_font_size * 0.6].max
        end
      end


      # Override this (and call super) to change the margin to the top
      # of the plot area.  Results in @border_top being set.
      #
      # This is 5 + the Title size + 5 + subTitle size
      def calculate_top_margin
        @border_top = 5
        @border_top += [title_font_size, y_title_font_size].max if (show_graph_title || (y_title_location ==:end))
        @border_top += 5
        @border_top += subtitle_font_size if show_graph_subtitle
      end

      def add_datapoint_text_and_popup( x, y, label )
        add_popup( x, y, label )
        make_datapoint_text( x, y, label )
      end

      # Adds pop-up point information to a graph only if the config option is set.
      def add_popup( x, y, label, style="" )
        if add_popups
          if( numeric?(label) )
            label = @number_format % label
          end
          txt_width = label.length * font_size * 0.6 + 10
          tx = (x+txt_width > @graph_width ? x-5 : x+5)
          t = @foreground.add_element( "text", {
            "x" => tx.to_s,
            "y" => (y - font_size).to_s,
            "class" => "dataPointLabel",
            "visibility" => "hidden",
          })
          t.attributes["style"] = "stroke-width: 2; fill: #000; #{style}"+
            (x+txt_width > @graph_width ? "text-anchor: end;" : "text-anchor: start;")
          t.text = label.to_s
          t.attributes["id"] = t.object_id.to_s

          # add a circle to catch the mouseover
          @foreground.add_element( "circle", {
            "cx" => x.to_s,
            "cy" => y.to_s,
            "r" => "#{popup_radius}",
            "style" => "opacity: 0",
            "onmouseover" =>
              "document.getElementById(#{t.object_id}).setAttribute('visibility', 'visible' )",
            "onmouseout" =>
              "document.getElementById(#{t.object_id}).setAttribute('visibility', 'hidden' )",
          })
        end # if add_popups
      end # add_popup

      # returns the longest label from an array of labels as string
      # each object in the array must support .to_s
      def get_longest_label(arry)
        longest_label = arry.max{|a,b|
              # respect number_format
              a = @number_format % a if numeric?(a)
              b = @number_format % b if numeric?(b)
              a.to_s.length <=> b.to_s.length
            }
        longest_label = @number_format % longest_label if numeric?(longest_label)
        return longest_label
      end

      # Override this (and call super) to change the margin to the bottom
      # of the plot area.  Results in @border_bottom being set.
      #
      # 7 + max label height(font size or string length, depending on rotate) + title height
      def calculate_bottom_margin
        @border_bottom = 7
        if key and key_position == :bottom
          @border_bottom += @data.size * (font_size + 5)
          @border_bottom += 10
        end
        @border_bottom += max_x_label_height_px
        if (show_x_title && (x_title_location ==:middle))
          @border_bottom += x_title_font_size + 5
        end
      end

      # returns the maximum height of the labels respect the rotation or 0 if
      # the labels are not shown
      def max_x_label_height_px
        return 0 if !show_x_labels

        if rotate_x_labels
          max_height = get_longest_label(get_x_labels).to_s.length * x_label_font_size * 0.6
        else
          max_height = x_label_font_size + 3
        end
        max_height += 5 + x_label_font_size if stagger_x_labels
        return max_height
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

        draw_x_axis
        draw_y_axis

        draw_x_labels
        draw_y_labels
      end

      # draws the x-axis; can be overridden by child classes
      def draw_x_axis
        # relative position on y-axis (hence @graph_height is our axis length)
        relative_position = calculate_rel_position(get_y_labels, field_height, @x_axis_position, @graph_height)
        # X-Axis
        y_offset = (1 - relative_position) * @graph_height
        @graph.add_element( "path", {
          "d" => "M 0 #{y_offset} h#@graph_width",
          "class" => "axis",
          "id" => "yAxis"
        })
      end

      # draws the y-axis; can be overridden by child classes
      def draw_y_axis
        # relative position on x-axis (hence @graph_width is our axis length)
        relative_position = calculate_rel_position(get_x_labels, field_width, @y_axis_position, @graph_width)
        # Y-Axis
        x_offset = relative_position * @graph_width
        @graph.add_element( "path", {
          "d" => "M #{x_offset} 0 v#@graph_height",
          "class" => "axis",
          "id" => "xAxis"
        })
      end

      # calculates the relative position betewen 0 and 1 of a value on the axis
      # can be multiplied with either @graph_height or @graph_width to get the
      # absolute position in pixels.
      # If labels are strings, checks if one of label matches with the value
      # and returns this position.
      # If labels are numeric, compute relative position between first and last value
      # If nothing else applies or the value is nil, the relative position is 0
      # @param labels [Array] the array of x or y labels, see {#get_x_labels} or {#get_y_labels}
      # @param segment_px [Float] number of pixels per label, see {#field_width} or {#field_height}
      # @param value [Numeric, String] the value for which the relative position is computed
      # @param axis_length [Numeric] either @graph_width or @graph_height
      # @return [Float] relative position between 0 and 1, returns 0
      def calculate_rel_position(labels, segment_px, value, axis_length)
        # default value, y-axis on the left side, or x-axis at bottom
        # puts "calculate_rel_position:"
        # p labels
        # p segment_px
        # p value
        # p axis_length
        relative_position = 0
        if !value.nil? # only
          if (labels[0].is_a? Numeric) && (labels[-1].is_a? Numeric) && (value.is_a? Numeric)
            # labels are numeric, compute relative position between first and last value
            range = labels[-1] - labels[0]
            position = value - labels[0]
            # compute how many segments long the offset is
            relative_to_segemts = position/range * (labels.size - 1)
            # convert from segments to relative position on the axis axis,
            # the number of segments (i.e. relative_to_segemts >= 1)
            relative_position = relative_to_segemts * segment_px / axis_length
          elsif labels[0].is_a? String
            # labels are strings, see if one of label matches with the position
            # and place the axis there
            index = labels.index(value)
            if !index.nil? # index would be nil if label is not found
              offset_px = segment_px * index
              relative_position = offset_px/axis_length   # between 0 and 1
            end
          end
        end # value.nil?
        return relative_position
      end

      # Where in the X area the label is drawn
      # Centered in the field, should be width/2.  Start, 0.
      def x_label_offset( width )
        0
      end

      # check if an object can be converted to float
      def numeric?(object)
        # true if Float(object) rescue false
        object.is_a? Numeric
      end

      # adds the datapoint text to the graph only if the config option is set
      def make_datapoint_text( x, y, value, style="" )
        if show_data_values
          textStr = value
          if( numeric?(value) )
            textStr = @number_format % value
          end
          # change anchor is label overlaps axis, normally anchor is middle (that's why we compute length/2)
          if x < textStr.length/2 * font_size
            style << "text-anchor: start;"
          elsif x > @graph_width - textStr.length/2 * font_size
            style << "text-anchor: end;"
          end
          # white background for better readability
          @foreground.add_element( "text", {
            "x" => x.to_s,
            "y" => y.to_s,
            "class" => "dataPointLabel",
            "style" => "#{style} stroke: #fff; stroke-width: 2;"
          }).text = textStr
          # actual label
          text = @foreground.add_element( "text", {
            "x" => x.to_s,
            "y" => y.to_s,
            "class" => "dataPointLabel"
          })
          text.text = textStr
          text.attributes["style"] = style if style.length > 0
        end
      end


      # Draws the X axis labels. The x-axis (@graph_width) is diveded into
      # {#get_x_labels.length} equal sections. The (center) x-coordinate for a
      # label hence is label_index * width_of_section
      def draw_x_labels
        stagger = x_label_font_size + 5
        label_width = field_width
        count = 0
        x_axis_already_drawn = false
        for label in get_x_labels
          if step_include_first_x_label == true then
            step = count % step_x_labels
          else
            step = (count + 1) % step_x_labels
          end
          # only draw every n-th label as defined by step_x_labels
          if step == 0 && show_x_labels then
            textStr = label.to_s
            if( numeric?(label) )
              textStr = @number_format % label
            end
            text = @graph.add_element( "text" )
            text.attributes["class"] = "xAxisLabels"
            text.text = textStr

            x = count * label_width + x_label_offset( label_width )
            y = @graph_height + x_label_font_size + 3
            #t = 0 - (font_size / 2)

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
              degrees = 90
              if numeric? rotate_x_labels
                degrees = rotate_x_labels
              end
              text.attributes["transform"] =
                "rotate( #{degrees} #{x} #{y-x_label_font_size} )"+
                " translate( 0 -#{x_label_font_size/4} )"
              text.attributes["style"] = "text-anchor: start"
            else
              text.attributes["style"] = "text-anchor: middle"
            end
          end # if step == 0 && show_x_labels

          draw_x_guidelines( label_width, count ) if show_x_guidelines
          count += 1
        end # for label in get_x_labels
      end # draw_x_labels


      # Where in the Y area the label is drawn
      # Centered in the field, should be width/2.  Start, 0.
      def y_label_offset( height )
        0
      end

      # override this method in child class
      # must return the array of labels for the x-axis
      def get_x_labels
      end

      # override this method in child class
      # must return the array of labels for the y-axis
      # this method defines @y_scale_division
      def get_y_labels
      end

      # space in px between x-labels
      def field_width
        # -1 is to use entire x-axis
        # otherwise there is always 1 division unused
        @graph_width.to_f / ( get_x_labels.length - 1 )
      end

      # space in px between the y-labels
      def field_height
        #(@graph_height.to_f - font_size*2*top_font) /
        #   (get_y_labels.length - top_align)
        @graph_height.to_f / get_y_labels.length
      end


      # Draws the Y axis labels, the Y-Axis (@graph_height) is divided equally into #get_y_labels.lenght sections
      # So the y coordinate for an arbitrary value is calculated as follows:
      #   y = @graph_height equals the min_value
      #   #normalize value of a single scale_division:
      #   count = value /(@y_scale_division)
      #   y = @graph_height - count * field_height
      #
      def draw_y_labels
        stagger = y_label_font_size + 5
        label_height = field_height
        count = 0
        y_offset = @graph_height + y_label_offset( label_height )
        y_offset += font_size/1.2 unless rotate_y_labels
        for label in get_y_labels
          if show_y_labels
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
            textStr = label.to_s
            if( numeric?(label) )
              textStr = @number_format % label
            end
            text.text = textStr
            if rotate_y_labels
              degrees = 90
              if numeric? rotate_y_labels
                degrees = rotate_y_labels
              end
              text.attributes["transform"] = "translate( -#{font_size} 0 ) "+
                "rotate( #{degrees} #{x} #{y} ) "
              text.attributes["style"] = "text-anchor: middle"
            else
              text.attributes["y"] = (y - (y_label_font_size/2)).to_s
              text.attributes["style"] = "text-anchor: end"
            end
          end # if show_y_labels
          draw_y_guidelines( label_height, count ) if show_y_guidelines
          count += 1
        end # for label in get_y_labels
      end # draw_y_labels


      # Draws the X axis guidelines, parallel to the y-axis
      def draw_x_guidelines( label_height, count )
        if count != 0
          @graph.add_element( "path", {
            "d" => "M#{label_height*count} 0 v#@graph_height",
            "class" => "guideLines"
          })
        end
      end


      # Draws the Y axis guidelines, parallel to the x-axis
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
            title_font_size + subtitle_font_size + 5 :
            subtitle_font_size
          @root.add_element("text", {
            "x" => (width / 2).to_s,
            "y" => (y_subtitle).to_s,
            "class" => "subTitle"
          }).text = graph_subtitle.to_s
        end

        if show_x_title
          if (x_title_location == :end)
            y = @graph_height + @border_top + x_title_font_size/2.0
            x = @border_left + @graph_width + x_title.length * x_title_font_size * 0.6/2.0
          else
            y = @graph_height + @border_top + x_title_font_size + max_x_label_height_px
            x = @border_left + @graph_width / 2
          end

          @root.add_element("text", {
            "x" => x.to_s,
            "y" => y.to_s,
            "class" => "xAxisTitle",
          }).text = x_title.to_s
        end

        if show_y_title
          if (y_title_location == :end)
            x = y_title.length * y_title_font_size * 0.6/2.0 # positioning is not optimal but ok for now
            y = @border_top - y_title_font_size/2.0
          else
            x = y_title_font_size + (y_title_text_direction==:bt ? 3 : -3)
            y = @border_top + @graph_height / 2
          end
          text = @root.add_element("text", {
            "x" => x.to_s,
            "y" => y.to_s,
            "class" => "yAxisTitle",
          })
          text.text = y_title.to_s
          # only rotate text if it is at the middle left of the y-axis
          # ignore the text_direction if y_title_location is set to :end
          if (y_title_location != :end)
            if y_title_text_direction == :bt
              text.attributes["transform"] = "rotate( -90, #{x}, #{y} )"
            else
              text.attributes["transform"] = "rotate( 90, #{x}, #{y} )"
            end
          end
        end
      end # draw_titles

      def keys
        i = 0
        return @data.collect{ |d| i+=1; d[:title] || "Serie #{i}" }
      end

      # Draws the legend on the graph
      def draw_legend
        if key
          group = @root.add_element( "g" )

          key_count = 0
          for key_name in keys
            y_offset = (key_box_size * key_count) + (key_count * key_spacing)
            group.add_element( "rect", {
              "x" => 0.to_s,
              "y" => y_offset.to_s,
              "width" => key_box_size.to_s,
              "height" => key_box_size.to_s,
              "class" => "key#{key_count+1}"
            })
            group.add_element( "text", {
              "x" => (key_box_size + key_spacing).to_s,
              "y" => (y_offset + key_box_size).to_s,
              "class" => "keyText"
            }).text = key_name.to_s
            key_count += 1
          end

          case key_position
          when :right
            x_offset = @graph_width + @border_left + (key_spacing * 2)
            y_offset = @border_top + (key_spacing * 2)
          when :bottom
            x_offset = @border_left + (key_spacing * 2)
            y_offset = @border_top + @graph_height + key_spacing
            if show_x_labels
              y_offset += max_x_label_height_px
            end
            y_offset += x_title_font_size + key_spacing if show_x_title
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
          names = $1
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
      # @param defs [REXML::Element]
      def add_defs defs
      end

      # Creates the XML document and adds the root svg element with
      # the width, height and viewBox attributes already set.
      # The element is stored as @root.
      #
      # In addition a rectangle background of the same size as the
      # svg is added.
      #
      def start_svg
        # Base document
        @doc = Document.new
        @doc << XMLDecl.new
        @doc << DocType.new( %q{svg PUBLIC "-//W3C//DTD SVG 1.0//EN" } +
          %q{"http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd"} )
        if style_sheet && style_sheet != '' && inline_style_sheet.to_s.empty?
          # if inline_style_sheet is defined, url style sheet is ignored
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
        if !no_css
          if inline_style_sheet && inline_style_sheet != ''
            style = defs.add_element( "style", {"type"=>"text/css"} )
            style << CData.new( inline_style_sheet )
          else
            @root << Comment.new(" include default stylesheet if none specified ")
            style = defs.add_element( "style", {"type"=>"text/css"} )
            style << CData.new( get_style )
          end
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

      #
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
      end # get_style

    end # class Graph
  end # module Graph
end # module SVG
