map.connect 'projects/:project_id/costlog/:action/:id', :controller => 'costlog', :project_id => /.+/

map.connect 'projects/:project_id/deliverables/:action', :controller => 'deliverables'
