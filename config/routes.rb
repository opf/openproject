OpenProject::Application.routes.draw do
  scope 'projects/:project_id' do
    resources :cost_reports, :only => [:index, :delete, :create, :update, :rename]
  end
end
