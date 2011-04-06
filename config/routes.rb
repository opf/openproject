#custom routes for this plugin
ActionController::Routing::Routes.draw do |map|
  map.resources :projects, :only => [] do |project|
    project.resources :meetings, :shallow => true, :member => {:copy => :get} do |meeting|
      meeting.resource :agenda, :controller => 'meeting_agendas', :only => [:update, :show], :member => {:history => :get, :diff => :get, :close => :put, :open => :put, :notify => :put, :preview => :post}
      meeting.resource :minutes, :controller => 'meeting_minutes', :only => [:update, :show], :member => {:history => :get, :diff => :get, :notify => :put, :preview => :post}
    end
  end
end