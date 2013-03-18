#custom routes for this plugin
OpenProject::Application.routes.draw do
  resources :projects, only: [] do
    shallow do
      resources :meetings do
        member do
          get :copy
        end
        resource :agenda, :controller => 'meeting_agendas', :only => [:update] do
          member do
            get :history
            get :diff
            put :close
            put :open
            put :notify
            post :preview
          end
        end
        resource :minutes, :controller => 'meeting_minutes', :only => [:update] do
          member do
            get :history
            get :diff
            put :notify
            post :preview
          end
        end
      end
    end
  end

  match '/meetings/:id/:tab' => 'meetings#show', :constraints => { :tab => /(agenda|minutes)/ }, :via => :get
  match '/meetings/:meeting_id/agenda/:version' => 'meeting_agendas#show', :constraints => { :version => /\d/ }, :via => :get
  match '/meetings/:meeting_id/minutes/:version' => 'meeting_minutes#show', :constraints => { :version => /\d/ }, :via => :get
  match '/projects/:project_id/meetings' => 'meetings#new', :via => :put
end
