map.connect 'projects/:project_id/backlogs', :controller => 'backlogs', :action => 'index'

map.resources :backlogs, :shallow => true do |backlog|
  backlog.resources :items do |item|
    item.resources :tasks
    item.resources :comments
  end
  
  backlog.resource :chart
end

map.resources :items
map.resources :tasks