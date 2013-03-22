#custom routes for this plugin

OpenProject::Application.routes.prepend do
  scope 'projects/:project_id' do
    resources :meetings, :only => [:new, :create, :index]
  end

  resources :meetings, :except => [:new, :create, :index] do

    resource :agenda, :controller => 'meeting_agendas', :only => [:update] do
      member do
        get :history
        get :diff
        put :close
        put :open
        put :notify
        post :preview
      end

      resources :versions, :only => [:show],
                           :controller => 'meeting_agendas'
    end

    resource :minutes, :controller => 'meeting_minutes', :only => [:update] do
      member do
        get :history
        get :diff
        put :notify
        post :preview
      end

      resources :versions, :only => [:show],
                           :controller => 'meeting_minutes'
    end

    member do
      get :copy
      match '/:tab' => 'meetings#show', :constraints => { :tab => /(agenda|minutes)/ },
                                        :via => :get,
                                        :as => 'tab'
    end
  end

  # TODO: check whether the rule for watching functionality in the core needs to be as restrictive
  # as it currently is. If the core rule can be formulated more flexibly, this scope can be removed.
  scope ':object_type/:object_id', :constraints => { :object_type => /meetings/,
                                                     :object_id => /\d+/ } do
    resources :watchers, :only => [:new]

    match '/watch' => 'watchers#watch', :via => :post
    match '/unwatch' => 'watchers#unwatch', :via => :delete
  end
end
