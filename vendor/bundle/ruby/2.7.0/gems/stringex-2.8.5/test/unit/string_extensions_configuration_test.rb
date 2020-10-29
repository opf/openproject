# encoding: UTF-8

require 'test_helper'
require 'stringex'

class StringExtensionsConfigurationTest < Test::Unit::TestCase
  def teardown
    Stringex::StringExtensions.unconfigure!
  end

  def test_can_set_base_settings
    Stringex::StringExtensions.configure do |c|
      c.replace_whitespace_with = "~"
    end
    assert_equal "foo~bar", "foo bar".to_url
  end
end
