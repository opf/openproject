require 'rexml/document'
require 'SVG/Graph/Graph'

module SVG
  module Graph
		# = Synopsis
		#
		# A superclass for bar-style graphs.  Do not attempt to instantiate
		# directly; use one of the subclasses instead.
		#
    # = Author
    #
    # Sean E. Russell <serATgermaneHYPHENsoftwareDOTcom>
		#
    # Copyright 2004 Sean E. Russell
		# This software is available under the Ruby license[LICENSE.txt]
    #
    class BarBase < SVG::Graph::Graph
			# Ensures that :fields are provided in the configuration.
      def initialize config
        raise "fields was not supplied or is empty" unless config[:fields] &&
        config[:fields].kind_of?(Array) &&
        config[:fields].length > 0
				super
			end

			# In addition to the defaults set in Graph::initialize, sets
			# [bar_gap] true
			# [stack] :overlap
			def set_defaults
        init_with( :bar_gap => true, :stack => :overlap )
      end

      #   Whether to have a gap between the bars or not, default
      #   is true, set to false if you don't want gaps.
      attr_accessor :bar_gap
      #   How to stack data sets.  :overlap overlaps bars with
      #   transparent colors, :top stacks bars on top of one another,
      #   :side stacks the bars side-by-side. Defaults to :overlap.
      attr_accessor :stack


			protected

      def max_value
        @data.collect{|x| x[:data].max}.max
      end

      def min_value
        min = 0
        if min_scale_value.nil? 
          min = @data.collect{|x| x[:data].min}.min
          min = min > 0 ? 0 : min
        else
          min = min_scale_value
        end
        return min
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
    end
  end
end
