module API
  module V3
    module WorkPackages
      class WorkPackagesAPI < Grape::API

        resources :work_packages do

          params do
            requires :id, desc: 'Work package id'
          end
          namespace ':id' do

            before do
              @work_package = WorkPackage.find(params[:id])
              model = WorkPackageModel.new(work_package: @work_package)
              @representer =  WorkPackageRepresenter.new(model, :activities, :users)
            end

            get do
              authorize(:work_packages_api, :get, context: @work_package.project)
              @representer.to_json
            end

          end

        end

      end
    end
  end
end
