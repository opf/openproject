require 'test/unit'
require 'coderay'

class PluginScannerTest < Test::Unit::TestCase
  
  def test_load
    require File.join(File.dirname(__FILE__), 'vhdl')
    assert_equal 'VHDL', CodeRay.scanner(:vhdl).class.name
  end
  
end
