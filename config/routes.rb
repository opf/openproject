# re-write
OpenProject::Application.routes.draw do
  # replace the standard overview-page with the my-project-page
  # careful: do not over-match the reserved path like /projects/new or /projects/level_list, see http://rubular.com/r/1uoiXyApCB
  get 'projects/:id', to: "my_projects_overviews#index" ,
                      constraints: {id: Regexp.new("(?!(#{Project::RESERVED_IDENTIFIERS.join('|')})$)(\\w|-)+") }




  get  'my_projects_overview/:id/page_layout',                        to: "my_projects_overviews#page_layout"
  post 'my_projects_overview/:id/page_layout/order_blocks',           to: "my_projects_overviews#order_blocks"
  post 'my_projects_overview/:id/page_layout/remove_block',           to: "my_projects_overviews#remove_block"
  post 'my_projects_overview/:id/page_layout/add_block',              to: "my_projects_overviews#add_block"
  put  'my_projects_overview/:id/page_layout/update_custom_element',  to: "my_projects_overviews#update_custom_element"
end

=begin
map.connect 'projects/:reservation.:format',
            :controller => 'projects',
            :action => reserved_identifier,
            :conditions => {:method => :get},
            :reservation => Regexp.new(reserved_identifier),
            :format => /\w+/
end

map.with_options :controller => 'my_projects_overviews'do |my|
  my.connect 'projects/:id', :action => 'index', :id => /[^\/.]+/, :conditions => {:method => :get} ---
  my.connect 'my_projects_overview/:id/page_layout', :action => 'page_layout'  -----
  my.connect 'my_projects_overview/:id/page_layout/add_block', :action => 'add_block' -----
  my.connect 'my_projects_overview/:id/page_layout/remove_block', :action => 'remove_block'
  my.connect 'my_projects_overview/:id/page_layout/order_blocks', :action => 'order_blocks' -----
  my.connect 'my_projects_overview/:id/page_layout/update_custom_element', :action => 'update_custom_element' ---
  my.connect 'my_projects_overview/:id/page_layout/destroy_attachment', :action => 'destroy_attachment', :conditions => {:method => :post}
  my.connect 'my_projects_overview/:id/page_layout/show_all_members', :action => 'show_all_members'
end

=end

