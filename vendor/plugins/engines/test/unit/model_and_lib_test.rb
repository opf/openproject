require File.dirname(__FILE__) + '/../test_helper'

class ModelAndLibTest < Test::Unit::TestCase

 	def test_WITH_a_model_defined_only_in_a_plugin_IT_should_load_the_model
 	  assert_equal 'AlphaPluginModel (from alpha_plugin)', AlphaPluginModel.report_location
  end
  
  def test_WITH_a_model_defined_only_in_a_plugin_lib_dir_IT_should_load_the_model
 	  assert_equal 'AlphaPluginLibModel (from alpha_plugin)', AlphaPluginLibModel.report_location
  end

  # app takes precedence over plugins
	
	def test_WITH_a_model_defined_in_both_app_and_plugin_IT_should_load_the_one_in_app
 	  assert_equal 'AppAndPluginModel (from app)',	AppAndPluginModel.report_location  
 	  assert_raises(NoMethodError) { AppAndPluginLibModel.defined_only_in_alpha_engine_version }
  end
	
	def test_WITH_a_model_defined_in_both_app_and_plugin_lib_dirs_IT_should_load_the_one_in_app
 	  assert_equal 'AppAndPluginLibModel (from lib)', AppAndPluginLibModel.report_location
 	  assert_raises(NoMethodError) { AppAndPluginLibModel.defined_only_in_alpha_engine_version }
  end

  # subsequently loaded plugins take precendence over previously loaded plugins
	
  # TODO
  #
  # this does work when we rely on $LOAD_PATH while it won't work when we use
  # Dependency constant autoloading. This somewhat confusing difference has
  # been there since at least Rails 1.2.x. See http://www.ruby-forum.com/topic/134529
  
  def test_WITH_a_model_defined_in_two_plugins_IT_should_load_the_latter_of_both
    require 'shared_plugin_model'
    assert_equal SharedPluginModel.report_location, 'SharedPluginModel (from beta_plugin)'
  end
end