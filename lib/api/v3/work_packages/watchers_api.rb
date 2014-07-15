module API
  module V3
    module WorkPackages
      class WatchersAPI < Grape::API

        resources :watchers do
          params do
            requires :user_id, desc: 'Id of the user watching the work package'
          end

          post do
            user = User.find params[:user_id]

            if @work_package.add_watcher(user)
              model = ::API::V3::Users::UserModel.new(user)
              @representer = ::API::V3::Users::UserRepresenter.new(model).to_json
            end

          end

        end
      end
    end
  end
end
