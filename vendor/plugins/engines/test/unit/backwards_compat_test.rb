#-- encoding: UTF-8
require File.dirname(__FILE__) + '/../test_helper'

class BackwardsCompatibilityTest < Test::Unit::TestCase
  def test_rails_module_plugin_method_should_delegate_to_engines_plugins
    assert_nothing_raised { Rails.plugins }
    assert_equal Engines.plugins, Rails.plugins 
  end
end