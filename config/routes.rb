ActionController::Routing::Routes.draw do |map|
    map.connect 'backlogs/:project_id', :controller => 'backlogs', :action => 'index'
    map.connect 'backlogs/:project_id/:sprint_id/burndown', :controller => 'backlogs', :action => 'burndown'
    map.connect 'backlogs/:project_id/issues', :controller => 'backlogs', :action => 'select_issues'
    map.connect 'backlogs/:project_id/:sprint_id/issues', :controller => 'backlogs', :action => 'select_issues'
    map.connect 'backlogs/:project_id/:sprint_id/wiki', :controller => 'backlogs', :action => 'wiki'
    map.connect 'backlogs/:project_id/:sprint_id/cards', :controller => 'backlogs', :action => 'taskboard_cards'
    map.connect 'backlogs/:project_id/cards', :controller => 'backlogs', :action => 'product_backlog_cards'
    map.connect 'backlogs/:project_id/:format/:key/calendar.xml', :controller => 'backlogs', :action => 'calendar'
end

