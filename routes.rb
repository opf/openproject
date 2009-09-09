map.connect 'projects/:project_id/costlog/:action/:id', :controller => 'costlog', :project_id => /.+/
map.connect 'projects/:project_id/deliverables/:action/:id', :controller => 'deliverables'
map.connect 'projects/:project_id/hourly_rate/:action/:id', :controller => 'hourly_rates'