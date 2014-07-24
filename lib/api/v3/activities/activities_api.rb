module API
  module V3
    module Activities
      class ActivitiesAPI < Grape::API

        resources :activities do

          params do
            requires :id, desc: 'Activity id'
          end
          namespace ':id' do

            before do
              @activity = Journal.find(params[:id])
              model = ::API::V3::Activities::ActivityModel.new(@activity)
              @representer =  ::API::V3::Activities::ActivityRepresenter.new(model, { current_user: current_user})
            end

            get do
              authorize(:view_project, context: @activity.journable.project)
              @representer.to_json
            end

            helpers do
              def save_activity(activity)
                if activity.save
                  model = ::API::V3::Activities::ActivityModel.new(activity)
                  representer = ::API::V3::Activities::ActivityRepresenter.new(model)

                  representer.to_json
                else
                  errors = activity.errors.full_messages.join(", ")
                  fail Errors::Validation.new(activity, description: errors)
                end
              end

              def authorize_edit_own(activity)
                return authorize({ controller: :journals, action: :edit }, context: @activity.journable.project)
                # raise API::Errors::Unauthorized.new(current_user) unless activity.editable_by?(current_user)
                # return false
              end
            end

            params do
              requires :comment, type: String
            end

            patch do
              authorize_edit_own(@activity)

              @activity.notes = params[:comment]

              save_activity(@activity)
            end

          end

        end

      end
    end
  end
end
