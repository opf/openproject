# Tests in this file ensure that:
#
# * Routes from plugins can be routed to
# * Named routes can be defined within a plugin

require File.dirname(__FILE__) + '/../test_helper'

class RoutesTest < ActionController::TestCase
  tests TestRoutingController
  
	def test_WITH_a_route_defined_in_a_plugin_IT_should_route_it
	  path = '/routes/an_action'
    opts = {:controller => 'test_routing', :action => 'an_action'}
    assert_routing path, opts
    assert_recognizes opts, path # not sure what exactly the difference is, but it won't hurt either
  end

	def test_WITH_a_route_for_a_namespaced_controller_defined_in_a_plugin_IT_should_route_it
	  path = 'somespace/routes/an_action'
    opts = {:controller => 'namespace/test_routing', :action => 'an_action'}
    assert_routing path, opts
    assert_recognizes opts, path
  end
  
  def test_should_properly_generate_named_routes
    get :test_named_routes_from_plugin
    assert_response_body '/somespace/routes'
  end
end