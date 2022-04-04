OpenProject::Application.routes.draw do
  namespace :admin do
    namespace :settings do
      resources :storages, controller: '/storages/admin/storages'
    end
  end

  scope 'projects/:project_id', as: 'project' do
    namespace 'settings' do
      resources :projects_storages, controller: '/storages/admin/projects_storages',
                                    except: %i[show update]
    end
  end
end
