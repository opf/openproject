#-- encoding: UTF-8
class TestRoutingController < ApplicationController
  def routed_action
    render_class_and_action
  end
  
  def test_named_routes_from_plugin
    render :text => plugin_route_path(:action => "index")
  end
end