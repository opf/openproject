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

              helpers do
                def save_work_package(work_package)
                  if work_package.save
                    model = ::API::V3::Activities::ActivityModel.new(work_package.journals.last)
                    representer = ::API::V3::Activities::ActivityRepresenter.new(model)

                    representer.to_json
                  else
                    errors = work_package.errors.full_messages.join(", ")
                    Errors::Validation.new(work_package, description: errors)
                  end
                end

                def save_activity(activity)
                  if activity.save
                    model = ::API::V3::Activities::ActivityModel.new(activity)
                    representer = ::API::V3::Activities::ActivityRepresenter.new(model)

                    representer.to_json
                  else
                    errors = activity.errors.full_messages.join(", ")
                    Errors::Validation.new(activity, description: errors)
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

                  save_activity(@activity)
                end
              end

            end

          end

        end

      end
    end
  end
end
