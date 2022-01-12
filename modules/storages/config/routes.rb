OpenProject::Application.routes.draw do
  scope 'admin/settings' do
    resources :storages, controller: 'storages/admin/storages'
  end
end
