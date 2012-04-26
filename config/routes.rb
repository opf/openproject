#custom routes for this plugin
ActionController::Routing::Routes.draw do |map|
  map.resources :projects, :only => [] do |project|
    project.resources :meetings, :shallow => true, :member => {:copy => :get} do |meeting|
      meeting.resource :agenda, :controller => 'meeting_agendas', :only => [:update], :member => {:history => :get, :diff => :get, :close => :put, :open => :put, :notify => :put, :preview => :post}
      meeting.resource :minutes, :controller => 'meeting_minutes', :only => [:update], :member => {:history => :get, :diff => :get, :notify => :put, :preview => :post}
    end
  end
  map.connect '/meetings/:id/:tab', :controller => 'meetings', :action => 'show', :tab => /(agenda|minutes)/, :conditions => {:method => :get}
  map.connect '/meetings/:meeting_id/agenda/:version', :controller => 'meeting_agendas', :action => 'show', :version => /\d/, :conditions => {:method => :get}
  map.connect '/meetings/:meeting_id/minutes/:version', :controller => 'meeting_minutes', :action => 'show', :version => /\d/, :conditions => {:method => :get}
end