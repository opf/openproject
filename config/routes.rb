ActionController::Routing::Routes.draw do |map|
  map.with_options :controller => 'my_projects_overviews' do |my|
    my.connect 'projects/:id', :action => 'index'
    my.connect 'projects/:id/page_layout', :action => 'page_layout'
    my.connect 'my_projects_overview/:id/add_block', :action => 'add_block'
    my.connect 'my_projects_overview/:id/remove_block', :action => 'remove_block'
    my.connect 'my_projects_overview/:id/order_blocks', :action => 'order_blocks'
  end
end
