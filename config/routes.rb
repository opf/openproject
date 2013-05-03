OpenProject::Application.routes.draw do

  scope 'projects/:project_id', :as => 'projects' do
    resources :cost_entries, :controller => 'costlog', :only => [:new, :create]

    resources :cost_objects, :only => [:new, :create, :index]

    resources :hourly_rates, :only => [:show, :edit, :update] do
      post :set_rate, :on => :member
    end
  end

  scope 'issues/:issue_id', :as => 'issues' do
    resources :cost_entries, :controller => 'costlog', :only => [:new]
  end

  resources :cost_entries, :controller => 'costlog', :only => [:index, :edit, :update, :destroy]

  resources :cost_objects, :only => [:show, :update, :destroy] do
    post :preview, :on => :member
  end

  resources :cost_types, :only => [:index, :new, :edit, :update] do
    # TODO: change to put or even better, replace with update method
    post :set_rate, :on => :member
    # TODO: change to destroy or even better, replace with destroy method
    post :toggle_delete, :on => :member
  end

  # TODO: this is a duplicate from a route defined under project/:project_id, check whether we really want to do that
  resources :hourly_rates, :only => [:edit, :update]
end
