OpenProject::Application.routes.draw do
  scope 'admin/settings' do
    resources :storages, controller: 'storages/admin/storages'
  end

  scope 'projects/:project_id', as: 'project' do
    namespace 'settings' do
      resources :projects_storages, controller: '/storages/admin/projects_storages',
                                    except: %i[show update]
    end
  end
end
