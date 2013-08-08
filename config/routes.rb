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
  post 'my_projects_overview/:id/page_layout/destroy_attachment',     to: "my_projects_overviews#destroy_attachment"
  post 'my_projects_overview/:id/page_layout/show_all_members',       to: "my_projects_overviews#show_all_members"
end
