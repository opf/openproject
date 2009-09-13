# Tests in this file ensure that:
#
# * plugin views are found
# * views in the application take precedence over those in plugins
# * views in subsequently loaded plugins take precendence over those in previously loaded plugins
# * this works for namespaced views accordingly

require File.dirname(__FILE__) + '/../test_helper'

class ViewLoadingTest < ActionController::TestCase
  def setup
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # plugin views should be found

 	def test_WITH_a_view_defined_only_in_a_plugin_IT_should_find_the_view
	  get_action_on_controller :a_view, :alpha_plugin
    assert_response_body 'alpha_plugin/a_view'
  end
	
	def test_WITH_a_namespaced_view_defined_only_in_a_plugin_IT_should_find_the_view
	  get_action_on_controller :a_view, :alpha_plugin, :namespace
    assert_response_body 'namespace/alpha_plugin/a_view'
  end

  # app takes precedence over plugins
	
	def test_WITH_a_view_defined_in_both_app_and_plugin_IT_should_find_the_one_in_app
	  get_action_on_controller :a_view, :app_and_plugin
    assert_response_body 'app_and_plugin/a_view (from app)'
  end
	
	def test_WITH_a_namespaced_view_defined_in_both_app_and_plugin_IT_should_find_the_one_in_app
	  get_action_on_controller :a_view, :app_and_plugin, :namespace
    assert_response_body 'namespace/app_and_plugin/a_view (from app)'
  end

  # subsequently loaded plugins take precendence over previously loaded plugins
	
	def test_WITH_a_view_defined_in_two_plugins_IT_should_find_the_latter_of_both
	  get_action_on_controller :a_view, :shared_plugin
    assert_response_body 'shared_plugin/a_view (from beta_plugin)'
  end
	
	def test_WITH_a_namespaced_view_defined_in_two_plugins_IT_should_find_the_latter_of_both
	  get_action_on_controller :a_view, :shared_plugin, :namespace
    assert_response_body 'namespace/shared_plugin/a_view (from beta_plugin)'
  end
  
  # layouts loaded from plugins

  def test_should_be_able_to_load_a_layout_from_a_plugin
    get_action_on_controller :action_with_layout, :alpha_plugin
    assert_response_body 'rendered in AlphaPluginController#action_with_layout (with plugin layout)'
  end
	
end
	