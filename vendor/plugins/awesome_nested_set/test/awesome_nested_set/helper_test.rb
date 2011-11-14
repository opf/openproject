#-- encoding: UTF-8
require File.dirname(__FILE__) + '/../test_helper'

module CollectiveIdea
  module Acts #:nodoc:
    module NestedSet #:nodoc:
      class AwesomeNestedSetTest < Test::Unit::TestCase
        include Helper
        fixtures :categories
        
        def test_nested_set_options
          expected = [
            [" Top Level", 1],
            ["- Child 1", 2],
            ['- Child 2', 3],
            ['-- Child 2.1', 4],
            ['- Child 3', 5],
            [" Top Level 2", 6]
          ]
          actual = nested_set_options(Category) do |c|
            "#{'-' * c.level} #{c.name}"
          end
          assert_equal expected, actual
        end
        
        def test_nested_set_options_with_mover
          expected = [
            [" Top Level", 1],
            ["- Child 1", 2],
            ['- Child 3', 5],
            [" Top Level 2", 6]
          ]
          actual = nested_set_options(Category, categories(:child_2)) do |c|
            "#{'-' * c.level} #{c.name}"
          end
          assert_equal expected, actual
        end
        
      end
    end
  end
end