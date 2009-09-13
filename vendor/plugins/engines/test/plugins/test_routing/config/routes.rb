ActionController::Routing::Routes.draw do |map|
  map.connect 'routes/:action', :controller => "test_routing"
  map.plugin_route 'somespace/routes/:action', :controller => "namespace/test_routing"
end