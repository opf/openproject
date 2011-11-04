ActionController::Routing::Routes.draw do |map|
  map.connect 'projects/new', :controller => 'projects', :action => 'new'
  map.connect 'projects/:id.:format:unused', :controller => 'projects', :action => 'show', :conditions => {:method => :get}, :id => /[^\/]+/, :format => /\w+/, :unused => nil

  map.with_options :controller => 'my_projects_overviews'do |my|
    my.connect 'projects/:id', :action => 'index', :id => /[^\/]+/, :conditions => {:method => :get}
    my.connect 'my_projects_overview/:id/page_layout', :action => 'page_layout'
    my.connect 'my_projects_overview/:id/page_layout/add_block', :action => 'add_block'
    my.connect 'my_projects_overview/:id/page_layout/remove_block', :action => 'remove_block'
    my.connect 'my_projects_overview/:id/page_layout/order_blocks', :action => 'order_blocks'
    my.connect 'my_projects_overview/:id/page_layout/update_custom_element', :action => 'update_custom_element'
    my.connect 'my_projects_overview/:id/page_layout/destroy_attachment', :action => 'destroy_attachment', :conditions => {:method => :post}
  end
end
