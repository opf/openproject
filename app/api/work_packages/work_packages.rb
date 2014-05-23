module WorkPackages
  class API < Grape::API

    resources :work_packages do

      params do
        optional :offset, type: Integer, default: 0, desc: 'Offset'
        optional :limit, type: Integer, default: 100, desc: 'Limit'
      end
      get do
        limit = params[:limit]
        offset = params[:offset]
        work_packages =
          WorkPackage
            .includes(:project, :author, :responsible, :assigned_to, :type, :status, :priority)
            .limit(limit)
            .offset(offset)
        work_packages_models = work_packages.map { |wp| WorkPackageModel.new(work_package: wp) }
        work_packages_representer = WorkPackagesRepresenter.new(work_packages_models)
        work_packages_representer.to_json
      end

      patch do
        'batch update work packages'
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
          authorize(:work_packages_api, :get, @work_package.project)
          @work_package_representer.to_json
        end

        params do
          optional :project_id, type: Integer, desc: 'Project id'
          optional :responsible_id, type: Integer, desc: 'Responsible user id'
        end
        patch do
          authorize(:work_packages_api, :patch, @work_package.project)
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
