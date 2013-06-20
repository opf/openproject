OpenProject::Application.routes.draw do

  scope 'projects/:project_id', :as => 'projects' do
    resources :cost_entries, :controller => 'costlog', :only => [:new, :create]

    resources :cost_objects, :only => [:new, :create, :index] do
      post :update_labor_budget_item, :on => :collection
      post :update_material_budget_item, :on => :collection
    end


    resources :hourly_rates, :only => [:show, :edit, :update] do
      post :set_rate, :on => :member
    end
  end

  scope 'issues/:issue_id', :as => 'issues' do
    resources :cost_entries, :controller => 'costlog', :only => [:new, :index]
  end

  resources :cost_entries, :controller => 'costlog', :only => [:edit, :update, :destroy]

  resources :cost_objects, :only => [:show, :update, :destroy, :edit] do
    get :copy, :on => :member
  end

  resources :cost_types, :only => [:index, :new, :edit, :update, :create] do
    # TODO: check if this can be replaced with update method
    put :set_rate, :on => :member
    # TODO: change to destroy or even better, replace with destroy method
    put :toggle_delete, :on => :member
  end

  # TODO: this is a duplicate from a route defined under project/:project_id, check whether we really want to do that
  resources :hourly_rates, :only => [:edit, :update]
end
