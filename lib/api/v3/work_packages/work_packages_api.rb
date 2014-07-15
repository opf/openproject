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
              model = ::API::V3::WorkPackages::WorkPackageModel.new(work_package: @work_package)
              @representer =  ::API::V3::WorkPackages::WorkPackageRepresenter.new(model, current_user: current_user)
            end

            get do
              authorize({ controller: :work_packages_api, action: :get }, context: @work_package.project)
              @representer.to_json
            end

            mount ::API::V3::WorkPackages::WatchersAPI
          end

        end

      end
    end
  end
end
