ActionController::Routing::Routes.draw do |map|
  # Add your own custom routes here.
  # The priority is based upon order of creation: first created -> highest priority.
  
  # Here's a sample route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  map.home '', :controller => 'welcome'

  map.connect 'wiki/:id/:page/:action', :controller => 'wiki', :page => nil
  map.connect 'roles/workflow/:id/:role_id/:tracker_id', :controller => 'roles', :action => 'workflow'
  map.connect 'help/:ctrl/:page', :controller => 'help'
  #map.connect ':controller/:action/:id/:sort_key/:sort_order'
  
  map.connect 'issues/:issue_id/relations/:action/:id', :controller => 'issue_relations'
  map.connect 'projects/:project_id/issues/:action', :controller => 'issues'
  map.connect 'projects/:project_id/news/:action', :controller => 'news'
  map.connect 'projects/:project_id/boards/:action/:id', :controller => 'boards'
  map.connect 'boards/:board_id/topics/:action/:id', :controller => 'messages'

  map.with_options :controller => 'repositories' do |omap|
    omap.repositories_show 'repositories/browse/:id/*path', :action => 'browse'
    omap.repositories_changes 'repositories/changes/:id/*path', :action => 'changes'
    omap.repositories_diff 'repositories/diff/:id/*path', :action => 'diff'
    omap.repositories_entry 'repositories/entry/:id/*path', :action => 'entry'
    omap.repositories_entry 'repositories/annotate/:id/*path', :action => 'annotate'
  end
  
  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  map.connect ':controller/service.wsdl', :action => 'wsdl'

 
  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id'
end
