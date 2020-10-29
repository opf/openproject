# Allows to customize datapoint shapes
class DataPoint
  OVERLAY = "OVERLAY" unless defined?(OVERLAY)
  DEFAULT_SHAPE = lambda{|x,y,line| ["circle", {
          "cx" => x,
          "cy" => y,
          "r" => "2.5",
          "class" => "dataPoint#{line}"
        }]
      } unless defined? DEFAULT_SHAPE
  CRITERIA = [] unless defined? CRITERIA
  
  # matchers are class scope. Once configured, each DataPoint instance will have
  # access to the same matchers
  # @param matchers [Array] multiple arrays of the following form:
  #     [ regex , 
  #       lambda taking three arguments (x,y, line_number for css)
  #         -> return value of the lambda must be an array: [svg tag name,  Hash with attributes for the svg tag, e.g. "points" and "class"]
  #     ]
  # @example
  #   DataPoint.configure_shape_criteria(
  #     [/.*/, lambda{|x,y,line| ['polygon', {
  #       "points" => "#{x-1.5},#{y+2.5} #{x+1.5},#{y+2.5} #{x+1.5},#{y-2.5} #{x-1.5},#{y-2.5}",
  #       "class" => "dataPoint#{line}"
  #       }]
  #     }]
  #   )
  def DataPoint.configure_shape_criteria(*matchers)
    CRITERIA.push(*matchers)
  end
  
  # 
  def DataPoint.reset_shape_criteria
    CRITERIA.clear
  end

  # creates a new DataPoint
  # @param x [Numeric] x coordinates of the point
  # @param y [Numeric] y coordinates of the point
  # @param line [Fixnum] line index of the current dataset (e.g. when multiple times Graph.add_data()), can be used to reference to the correct css class
  def initialize(x, y, line)
    @x = x
    @y = y
    @line = line
  end
  
  # @return [Array<Array>] see example
  # @example Return value
  #   # two dimensional array, the splatted (*) inner array can be used as argument to REXML::add_element
  #   [["svgtag",  {"points" => "", "class"=> "dataPoint#{line}" } ], ["svgtag", {"points"=>"", "class"=> ""}], ...]
  # @exmple Usage
  #   dp = DataPoint.new(x, y, line).shape(data[:description])
  #   # for each svg we insert it to the graph
  #   dp.each {|s| @graph.add_element( *s )}
  #
  def shape(description=nil)
    # select all criteria with size 2, and collect rendered lambdas in an array 
    shapes = CRITERIA.select {|criteria|
      criteria.size == 2
    }.collect {|regexp, proc|
      proc.call(@x, @y, @line) if description =~ regexp
    }.compact
    # if above did not render anything use the defalt shape
    shapes = [DEFAULT_SHAPE.call(@x, @y, @line)] if shapes.empty?

    overlays = CRITERIA.select { |criteria|
      criteria.last == OVERLAY
    }.collect { |regexp, proc|
      proc.call(@x, @y, @line) if description =~ regexp
    }.compact

    return shapes + overlays
  end
end
