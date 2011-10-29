#-- encoding: UTF-8
# Tests in this file ensure that:
#
# * plugin controller actions are found
# * actions defined in application controllers take precedence over those in plugins
# * actions in controllers in subsequently loaded plugins take precendence over those in previously loaded plugins
# * this works for actions in namespaced controllers accordingly

require File.dirname(__FILE__) + '/../test_helper'

class ControllerLoadingTest < ActionController::TestCase
  def setup
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # plugin controller actions should be found

	def test_WITH_an_action_defined_only_in_a_plugin_IT_should_use_this_action
	  get_action_on_controller :an_action, :alpha_plugin
    assert_response_body 'rendered in AlphaPluginController#an_action'
  end
  
	def test_WITH_an_action_defined_only_in_a_namespaced_plugin_controller_IT_should_use_this_action
	  get_action_on_controller :an_action, :alpha_plugin, :namespace
    assert_response_body 'rendered in Namespace::AlphaPluginController#an_action'
  end

  # app takes precedence over plugins

  def test_WITH_an_action_defined_in_both_app_and_plugin_IT_should_use_the_one_in_app
	  get_action_on_controller :an_action, :app_and_plugin
    assert_response_body 'rendered in AppAndPluginController#an_action (from app)'
  end
  
  def test_WITH_an_action_defined_in_namespaced_controllers_in_both_app_and_plugin_IT_should_use_the_one_in_app
	  get_action_on_controller :an_action, :app_and_plugin, :namespace
    assert_response_body 'rendered in Namespace::AppAndPluginController#an_action (from app)'
  end

  # subsequently loaded plugins take precendence over previously loaded plugins

  def test_WITH_an_action_defined_in_two_plugin_controllers_IT_should_use_the_latter_of_both
	  get_action_on_controller :an_action, :shared_plugin
    assert_response_body 'rendered in SharedPluginController#an_action (from beta_plugin)'
  end
  
  def test_WITH_an_action_defined_in_two_namespaced_plugin_controllers_IT_should_use_the_latter_of_both
	  get_action_on_controller :an_action, :shared_plugin, :namespace
    assert_response_body 'rendered in Namespace::SharedPluginController#an_action (from beta_plugin)'
  end
end
