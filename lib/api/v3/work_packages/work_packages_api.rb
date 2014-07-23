module API
  module V3
    module WorkPackages
      class WorkPackagesAPI < Grape::API

        resources :work_packages do

          params do
            requires :id, desc: 'Work package id'
          end
          namespace ':id' do

            helpers do
              attr_reader :work_package
            end

            before do
              @work_package = WorkPackage.find(params[:id])
              model = ::API::V3::WorkPackages::WorkPackageModel.new(work_package: @work_package)
              @representer =  ::API::V3::WorkPackages::WorkPackageRepresenter.new(model, { current_user: current_user }, :activities, :users)
            end

            get do
              authorize({ controller: :work_packages_api, action: :get }, context: @work_package.project)
              @representer
            end

            resource :activities do

              helpers do
                def save_work_package(work_package)
                  if work_package.save
                    model = ::API::V3::Activities::ActivityModel.new(work_package.journals.last)
                    representer = ::API::V3::Activities::ActivityRepresenter.new(model)

                    representer
                  else
                    errors = work_package.errors.full_messages.join(", ")
                    fail Errors::Validation.new(work_package, description: errors)
                  end
                end
              end

              params do
                requires :comment, type: String
              end
              post do
                authorize({ controller: :journals, action: :new }, context: @work_package.project)

                @work_package.journal_notes = params[:comment]

                save_work_package(@work_package)
              end

            end

            mount ::API::V3::WorkPackages::WatchersAPI
            mount ::API::V3::WorkPackages::StatusesAPI
          end

        end

      end
    end
  end
end
