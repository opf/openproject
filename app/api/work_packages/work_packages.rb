module WorkPackages
  class API < Grape::API

    resources :work_packages do

      get do
        'list all work packages'
      end

      post do
        'create new work package(s)'
      end

      patch do
        'batch update work packages'
      end

      delete do
        'batch delete work packages'
      end

      params do
        requires :id, type: Integer, desc: 'Work package id.'
      end
      namespace ':id' do

        before do
          @work_package = WorkPackage.find(params[:id])
          work_package_model = WorkPackageModel.new(work_package: @work_package)
          @work_package_representer = WorkPackageRepresenter.new(work_package_model)
        end

        get do
          @work_package_representer.to_json
        end

        params do
          optional :project_id, type: Integer, desc: 'Project id'
          optional :responsible_id, type: Integer, desc: 'Responsible user id'
        end
        patch do
          params.delete(:id)
          @work_package_representer.from_json(params.to_json)
          if @work_package_representer.represented.valid?
            @work_package_representer.represented.save!
            @work_package_representer.to_json
          else
            @work_package_representer.represented.errors.to_json
          end
        end

      end
    end
  end
end
