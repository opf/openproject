require File.dirname(__FILE__) + '/../test_helper'

class PluginsTest < Test::Unit::TestCase
  
  def test_should_allow_access_to_plugins_by_strings_or_symbols
    p = Engines.plugins["alpha_plugin"]
    q = Engines.plugins[:alpha_plugin]
    assert_kind_of Engines::Plugin, p
    assert_equal p, q
  end
end