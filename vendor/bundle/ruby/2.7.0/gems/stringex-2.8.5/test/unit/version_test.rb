# encoding: UTF-8

require 'test_helper'
require 'stringex'

class VersionTest < Test::Unit::TestCase
  def test_version_is_exposed
    assert_nothing_raised do
      Stringex::Version
    end
  end
end
