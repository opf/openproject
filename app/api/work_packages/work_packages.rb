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
          optional :type, desc: 'Type'
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
          declared_params = declared(params).reject{ |key, value| key.to_sym == :id || value.nil? }

          @work_package_representer.from_json(declared_params.to_json)
          if @work_package_representer.represented.valid?
            @work_package_representer.represented.save
            @work_package_representer.to_json
          else
            @work_package_representer.represented.errors.to_json
          end
        end

      end
    end
  end
end
