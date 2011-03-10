ActionController::Routing::Routes.draw do |map|
  map.connect 'projects/:project_id/issues/printable', :controller => 'issues', :action => 'printable'
end
