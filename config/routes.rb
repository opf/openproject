#custom routes for this plugin
ActionController::Routing::Routes.draw do |map|
  map.resources :projects, :only => [] do |project|
    project.resources :meetings, :shallow => true do |meeting|
      meeting.resource :meeting_agenda, :as => 'agenda', :only => [:update], :member => {:history => :get}
      meeting.resource :meeting_minutes, :as => 'minutes', :only => [:update], :member => {:history => :get}
    end
  end
end