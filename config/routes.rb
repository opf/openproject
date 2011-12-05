ActionController::Routing::Routes.draw do |map|
  map.connect 'projects/:project_id/issues/printable', :controller => 'issues', :action => 'printable'
  map.connect 'issues/printable', :controller => 'issues', :action => 'printable'
end
