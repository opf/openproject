require 'rexml/document'
require 'json'

module SVG
  module Graph

    # This class provides a lightweight generator for html code indluding c3js based
    # graphs specified as javascript.
    class C3js

      # By default, the generated html code links the javascript and css dependencies
      # to the d3 and c3 libraries in the <head> element. The latest versions of d3 and c3 available
      # at the time of gem release are used through cdnjs.
      # Custom versions of d3 and c3 can easily be used by specifying the corresponding keys
      # in the optional Hash argument.
      #
      # If the dependencies are http(s) urls a simple href / src link is inserted in the
      # html header.
      # If you want to create a fully offline capable html file, you can do this by
      # downloading the (minified) versions of d3.js, c3.css, c3.js to disk and then
      # point to the files instead of http links. This will then inline the complete
      # script and css payload directly into the generated html page.
      #
      #
      # @option opts [String] "inline_dependencies" if true will inline the script and css
      #                       parts of d3 and c3 directly into html, otherwise they are referred
      #                       as external dependencies. default: false
      # @option opts [String] "d3_js"  url or path to local files. default: d3.js url via cdnjs
      # @option opts [String] "c3_css" url or path to local files. default: c3.css url via cdnjs
      # @option opts [String] "c3_js"  url or path to local files. default: c3.js url via cdnjs
      # @example create a simple graph
      #   my_graph = SVG::Graph::C3js.new("my_funny_chart_var")
      # @example create a graph with custom version of C3 and D3
      #   # use external dependencies
      #   opts = {
      #     "d3_js"  => "https://cdnjs.cloudflare.com/ajax/libs/d3/5.7.0/d3.min.js",
      #     "c3_css" => "https://cdnjs.cloudflare.com/ajax/libs/c3/0.6.8/c3.min.css",
      #     "c3_js"  => "https://cdnjs.cloudflare.com/ajax/libs/c3/0.6.8/c3.min.js"
      #   }
      #   # or inline dependencies into generated html
      #   opts = {
      #     "inline_dependencies" => true,
      #     "d3_js"  => "/path/to/local/copy/of/d3.min.js",
      #     "c3_css" => "/path/to/local/copy/of/c3.min.css",
      #     "c3_js"  => "/path/to/local/copy/of/c3.min.js"
      #   }
      #   my_graph = SVG::Graph::C3js.new("my_funny_chart_var", opts)
      def initialize(opts = {})
        default_opts = {
          "inline_dependencies" => false,
          "d3_js"  => "https://cdnjs.cloudflare.com/ajax/libs/d3/5.12.0/d3.min.js",
          "c3_css" => "https://cdnjs.cloudflare.com/ajax/libs/c3/0.7.11/c3.min.css",
          "c3_js"  => "https://cdnjs.cloudflare.com/ajax/libs/c3/0.7.11/c3.min.js"
        }
        @opts = default_opts.merge(opts)
        if @opts["inline_dependencies"]
          # we replace the values in the opts Hash by the referred file contents
          ["d3_js", "c3_css", "c3_js"].each do |key|
            if !File.file?(@opts[key])
              raise "opts[\"#{key}\"]: No such file - #{File.expand_path(@opts[key])}"
            end
            @opts[key] = File.read(@opts[key])
          end # ["d3_js", "c3_css", "c3_js"].each
        end # if @opts["inline_dependencies"]
        start_document()
      end # def initialize

      # Adds a javascript/json C3js chart definition into the div tag
      # @param javascript [String, Hash] see example
      # @param js_chart_variable_name [String] only needed if the `javascript` parameter is a Hash.
      #    unique variable name representing the chart in javascript scope.
      #    Note this is a global javascript "var" so make sure to avoid name clashes
      #    with other javascript us might use on the same page.
      #
      # @raise
      # @example
      #   # see http://c3js.org/examples.html
      #   # since ruby 2.3 you can use string symbol keys:
      #   chart_spec = {
      #     # bindto is mandatory
      #     "bindto": "#this_is_my_awesom_graph",
      #     "data": {
      #       "columns": [
      #           ['data1', 30, 200, 100, 400, 150, 250],
      #           ['data2', 50, 20, 10, 40, 15, 25]
      #       ]
      #   }
      #   # otherwise simply write plain javascript into a heredoc string:
      #   # make sure to include the  var <chartname> = c3.generate() if using heredoc
      #   chart_spec_string =<<-HEREDOC
      #   var mychart1 = c3.generate({
      #     // bindto is mandatory
      #     "bindto": "#this_is_my_awesom_graph",
      #     "data": {
      #       "columns": [
      #           ['data1', 30, 200, 100, 400, 150, 250],
      #           ['data2', 50, 20, 10, 40, 15, 25]
      #       ]
      #   });
      #   HEREDOC
      #   graph.add_chart_spec(chart_spec, "my_chart1")
      #   # or
      #   graph.add_chart_spec(chart_spec_string)
      def add_chart_spec(javascript, js_chart_variable_name = "")
        if javascript.kind_of?(Hash)
          if js_chart_variable_name.to_s.empty? || js_chart_variable_name.to_s.match(/\s/)
            raise "js_chart_variable_name ('#{js_chart_variable_name.to_s}') cannot be empty or contain spaces, " +
                  "a valid javascript variable name is needed."
          end
          chart_spec = JSON(javascript)
          inline_script = "var #{js_chart_variable_name} = c3.generate(#{chart_spec});"
        elsif javascript.kind_of?(String)
          inline_script = javascript
          if !inline_script.match(/c3\.generate/)
            raise "var <chartname> = c3.generate({...}) statement is missing in javascript string"
          end
        else
          raise "Unsupported argument type: #{javascript.class}"
        end
        # (.+?)" means non-greedy match up to next double quote
        if m = inline_script.match(/"bindto":\s*"#(.+?)"/)
          @bindto = m[1]
        else
          raise "Missing chart specification is missing the mandatory \"bindto\" key/value pair."
        end
        add_div_element_for_graph()
        add_javascript() {inline_script}
      end # def add_chart_spec

      # Appends a <script> element to the <div> element, this can be used to add additional animations
      # but any script can also directly be part of the js_chart_specification in the #add_chart_spec
      # method when you use a HEREDOC string as input.
      # @param attrs [Hash] attributes for the <script> element. The following attribute
      #   is added by default:  type="text/javascript"
      # @yieldreturn [String] the actual javascript code to be added to the <script> element
      # @return [REXML::Element] the Element which was just added
      def add_javascript(attrs={}, &block)
        default_attrs = {"type" => "text/javascript"}
        attrs = default_attrs.merge(attrs)
        temp = REXML::Element.new("script")
        temp.add_attributes(attrs)
        @svg.add_element(temp)
        raise "Block argument is mandatory" unless block_given?
        script_content = block.call()
        cdata(script_content, temp)
      end # def add_javascript


      # @return [String] the complete html file
      def burn
        f = REXML::Formatters::Pretty.new(0)
        out = ''
        f.write(@doc, out)
        out
      end # def burn

      # Burns the graph but returns only the <div> node as String without the
      # Doctype and XML / HTML Declaration. This allows easy integration into
      # existing xml/html documents. The Javascript to create the C3js graph
      # is inlined into the div tag.
      #
      # You have to take care to refer the proper C3 and D3 dependencies in your
      # html page.
      #
      # @return [String] the div element into which the graph will be rendered
      #    by C3.js
      def burn_svg_only
        # initialize all instance variables by burning the graph
        burn
        f = REXML::Formatters::Pretty.new(0)
        f.compact = true
        out = ''
        f.write(@svg, out)
        return out
      end # def burn_svg_only

      private

      # Appends a <style> element to the <div> element, this can be used to add additional animations
      # but any script can also directly be part of the js_chart_specification in the #add_chart_spec
      # method when you use a HEREDOC string as input.
      # @yieldreturn [String] the actual javascript code to be added to the <script> element
      # @return [REXML::Element] the Element which was just added
      def add_css_to_head(&block)
        raise "Block argument is mandatory" unless block_given?
        css_content_or_url = block.call()
        if @opts["inline_dependencies"]
          # for inline css use "style"
          temp = REXML::Element.new("style")
          attrs = {
            "type" => "text/css"
          }
          cdata(css_content_or_url, temp)
        else
          # for external css use "link"
          temp = REXML::Element.new("link")
          attrs = {
            "href" => @opts["c3_css"],
            "rel" => "stylesheet"
          }
        end
        temp.add_attributes(attrs)
        @head.add_element(temp)
      end # def add_css_to_head

      # Appends a <script> element to the <head> element, this can be used to add
      # the dependencies/libraries.
      # @yieldreturn [String] the actual javascript code to be added to the <script> element
      # @return [REXML::Element] the Element which was just added
      def add_js_to_head(&block)
        raise "Block argument is mandatory" unless block_given?
        script_content_or_url = block.call()
        attrs = {"type" => "text/javascript"}
        temp = REXML::Element.new("script")
        if @opts["inline_dependencies"]
          cdata(script_content_or_url, temp)
        else
          attrs["src"] = script_content_or_url
          # note: self-closing xml script tags are not allowed in html. Only for xhtml this is ok.
          # Thus add a space textnode to enforce closing tags.
          temp.add_text(" ")
        end
        temp.add_attributes(attrs)
        @head.add_element(temp)
      end # def add_js_to_head

      def start_document
        # Base document
        @doc = REXML::Document.new
        @doc << REXML::XMLDecl.new("1.0", "UTF-8")
        @doc << REXML::DocType.new("html")
        # attribute xmlns is needed, otherwise the browser will only display raw xml
        # instead of rendering the page
        @html = @doc.add_element("html", {"xmlns" => 'http://www.w3.org/1999/xhtml'})
        @html << REXML::Comment.new( " "+"\\"*66 )
        @html << REXML::Comment.new( " Created with SVG::Graph - https://github.com/lumean/svg-graph2" )
        @head = @html.add_element("head")
        @body = @html.add_element("body")
        @head.add_element("meta", {"charset" => "utf-8"})
        add_js_to_head() {@opts["d3_js"]}
        add_css_to_head() {@opts["c3_css"]}
        add_js_to_head() {@opts["c3_js"]}
      end # def start_svg

      # @param attrs [Hash] html attributes for the <div> tag to which svg graph
      #                     is bound to by C3js. The "id" attribute
      #                     is filled automatically by this method. default: an empty hash {}
      def add_div_element_for_graph(attrs={})
        if @bindto.to_s.empty?
          raise "#add_chart_spec needs to be called before the svg can be added"
        end
        attrs["id"] = @bindto
        @svg = @body.add_element("div", attrs)
      end

      # Surrounds CData tag with c-style comments to remain compatible with normal html.
      # This can be used to inline arbitrary javascript code and is compatible with many browsers.
      # Example /*<![CDATA[*/\n ...content ... \n/*]]>*/
      # @param str [String] the string to be enclosed in cdata
      # @param parent_element [REXML::Element] the element to which cdata should be added
      # @return [REXML::Element] parent_element
      def cdata(str, parent_element)
        # somehow there is a problem with CDATA, any text added after will automatically go into the CDATA
        # so we have do add a dummy node after the CDATA and then add the text.
        parent_element.add_text("/*")
        parent_element.add(REXML::CData.new("*/\n"+str+"\n/*"))
        parent_element.add(REXML::Comment.new("dummy comment to make c-style comments for cdata work"))
        parent_element.add_text("*/")
      end # def cdata

    end # class C3js

  end # module Graph
end # module SVG