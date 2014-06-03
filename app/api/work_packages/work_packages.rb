module WorkPackages
  class API < Grape::API

    resources :work_packages do

      params do
        requires :id, type: Integer, desc: 'Work package id.'
      end
      namespace ':id' do

        before do
          @work_package = WorkPackage.find(params[:id])
          work_package_model = WorkPackageModel.new(work_package: @work_package)
          @work_package_representer = WorkPackageRepresenter.new(work_package_model)
        end

        params do
          optional :subject, desc: 'Subject'
          optional :description, desc: 'Description'
          optional :status, desc: 'Status'
          optional :priority, desc: 'Priority'
          optional :startDate
          optional :dueDate
          optional :estimatedTime, desc: 'Estimated time`'
          optional :percentageDone, desc: 'Percentage done'
          optional :versionId, desc: 'Version id'
          optional :projectId, desc: 'Project id'
          optional :responsibleId, desc: 'Responsible user id'
          optional :assigneeId, desc: 'Assignee id'
        end
        patch do
          authorize(:work_packages_api, :patch, @work_package.project)

          users_params = request.POST
          declared_params = declared(users_params)

          allowed_params = { }
          users_params.each do |key, value|
            key = key.to_sym
            unless declared_params.include?(key)
              raise UnwritablePropertyError.new(key)
            end
            allowed_params[key] = value
          end

          @work_package_representer.from_json(allowed_params.to_json)
          if @work_package_representer.represented.valid?
            @work_package_representer.represented.save
            @work_package_representer.to_json
          else
            raise ValidationError.new(@work_package_representer.represented)
          end
        end

      end
    end
  end
end
