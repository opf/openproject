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
              @representer =  ::API::V3::WorkPackages::WorkPackageRepresenter.new(model, :activities, :users)
            end

            get do
              authorize({ controller: :work_packages_api, action: :get }, context: @work_package.project)
              @representer.to_json
            end

            resource :activities do

              params do
                requires :comment, type: String
              end
              post do
                authorize({ controller: :journals, action: :new }, context: @work_package.project)

                @work_package.journal_notes = params[:comment]
                @work_package.save!

                EmptyResponse
              end

              params do
                requires :activity_id, desc: 'Work package activity id'
              end
              namespace ':activity_id' do

                before do
                  @activity = Journal.find(params[:activity_id])
                end

                params do
                  requires :comment, type: String
                end
                put do
                  authorize({ controller: :journals, action: :edit }, context: @work_package.project)

                  @activity.notes = params[:comment]
                  @activity.save!

                  EmptyResponse
                end
              end

            end

          end

        end

      end
    end
  end
end
