# re-write
OpenProject::Application.routes.draw do
  Project::RESERVED_IDENTIFIERS.each do |reserved_identifier|

    get 'projects/:reservation.:format', to: "projects##{reserved_identifier}"
  end

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
  my.connect 'projects/:id', :action => 'index', :id => /[^\/.]+/, :conditions => {:method => :get}
  my.connect 'my_projects_overview/:id/page_layout', :action => 'page_layout'
  my.connect 'my_projects_overview/:id/page_layout/add_block', :action => 'add_block'
  my.connect 'my_projects_overview/:id/page_layout/remove_block', :action => 'remove_block'
  my.connect 'my_projects_overview/:id/page_layout/order_blocks', :action => 'order_blocks'
  my.connect 'my_projects_overview/:id/page_layout/update_custom_element', :action => 'update_custom_element'
  my.connect 'my_projects_overview/:id/page_layout/destroy_attachment', :action => 'destroy_attachment', :conditions => {:method => :post}
  my.connect 'my_projects_overview/:id/page_layout/show_all_members', :action => 'show_all_members'
end

=end

