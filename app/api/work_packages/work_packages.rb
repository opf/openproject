module WorkPackages
  class API < Grape::API

    resources :work_packages do
      get do
        work_packages = WorkPackage.all
      end

      get ':id' do
        work_package = current_user.work_packages.find(params[:id])
        WorkPackageRepresenter.new(work_package).to_json
      end

      patch ':id' do
        "work package update"
      end

      delete :':id' do
        "work package delete"
      end

      patch do
        "work packages batch update"
      end

      delete do
        "work packages batch delete"
      end
    end

    resources :projects do
        namespace ':project_id' do
          get :work_packages do
            project = Project.find(params[:project_id])
            project.work_packages
          end

          post :work_packages do
            "create work packages for project (batch and single)"
          end
        end
      end

  end
end
