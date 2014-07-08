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
              @representer =  ::API::V3::Activities::ActivityRepresenter.new(model)
            end

            get do
              @representer.to_json
            end

          end

        end

      end
    end
  end
end
