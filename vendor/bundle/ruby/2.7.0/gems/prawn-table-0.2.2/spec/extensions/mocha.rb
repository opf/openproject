# encoding: utf-8

# Allow speccing things when an expectation matcher runs. Similar to #with, but
# always succeeds.
#
#   @pdf.expects(:stroke_line).checking do |from, to|
#     @pdf.map_to_absolute(from).should == [0, 0]
#   end
#
# Note that the outer expectation does *not* fail only because the inner one
# does; in the above example, the outer expectation would only fail if
# stroke_line were not called.

class ParameterChecker < Mocha::ParametersMatcher
  def initialize(&matching_block)
    @expected_parameters = [Mocha::ParameterMatchers::AnyParameters.new]
    @matching_block = matching_block
  end

  def match?(actual_parameters = [])
    @matching_block.call(*actual_parameters)

    true # always succeed
  end
end

class Mocha::Expectation
  def checking(&block)
    @parameters_matcher = ParameterChecker.new(&block)
    self
  end
end


# Equivalent to expects(method_name).at_least(0). More useful when combined
# with parameter matchers to ignore certain calls for the sake of parameter
# matching.
#
#   @pdf.ignores(:stroke_color=).with("000000")
#   @pdf.expects(:stroke_color=).with("ff0000")
#
module Mocha::ObjectMethods
  def ignores(method_name)
    expects(method_name).at_least(0)
  end
end
