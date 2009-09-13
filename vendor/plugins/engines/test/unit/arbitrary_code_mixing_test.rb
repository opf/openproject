require File.dirname(__FILE__) + '/../test_helper'

class ArbitraryCodeMixingTest < Test::Unit::TestCase  
  def setup
    Engines.code_mixing_file_types = %w(controller helper)
  end
  
  def test_should_allow_setting_of_different_code_mixing_file_types
    assert_nothing_raised {
      Engines.mix_code_from :things
    }
  end

  def test_should_add_new_types_to_existing_code_mixing_file_types
    Engines.mix_code_from :things
    assert_equal ["controller", "helper", "thing"], Engines.code_mixing_file_types
    Engines.mix_code_from :other
    assert_equal ["controller", "helper", "thing", "other"], Engines.code_mixing_file_types
  end
  
  def test_should_allow_setting_of_multiple_types_at_once
    Engines.mix_code_from :things, :other
    assert_equal ["controller", "helper", "thing", "other"], Engines.code_mixing_file_types
  end
   
  def test_should_singularize_elements_to_be_mixed
    # this is the only test using mocha, so let's try to work around it
    # also, this seems to be already tested with the :things in the tests above
    # arg = stub(:to_s => stub(:singularize => "element")) 
    Engines.mix_code_from :elements
    assert Engines.code_mixing_file_types.include?("element")
  end
  
  # TODO doesn't seem to work as expected?
  
  # def test_should_successfully_mix_custom_types
  #   Engines.mix_code_from :things    
  #   assert_equal 'Thing (from app)', Thing.from_app
  #   assert_equal 'Thing (from test_code_mixing)', Thing.from_plugin
  # end
end