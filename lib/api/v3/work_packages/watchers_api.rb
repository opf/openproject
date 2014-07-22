module API
  module V3
    module WorkPackages
      class WatchersAPI < Grape::API

        get '/available_watchers' do
          available_watchers = @work_package.possible_watcher_users
          build_representer(
            available_watchers,
            ::API::V3::Users::UserModel,
            ::API::V3::Watchers::WatchersRepresenter,
            as: :available_watchers
          )
        end

        resources :watchers do

          params do
            requires :user_id, desc: 'The watcher\'s user id', type: Integer
          end
          post do
            if current_user.id == params[:user_id]
              authorize(:view_work_packages, context: @work_package.project)
            else
              authorize(:add_work_package_watchers, context: @work_package.project)
            end

            user = User.find params[:user_id]

            Services::CreateWatcher.new(@work_package, user).run(
              -> (result) { status(200) unless result[:created]},
              -> (watcher) { raise ::API::Errors::Validation.new(watcher) }
            )

            build_representer(user, ::API::V3::Users::UserModel, ::API::V3::Users::UserRepresenter)
          end

          namespace ':user_id' do
            params do
              requires :user_id, desc: 'The watcher\'s user id', type: Integer
            end

            delete do
              if current_user.id == params[:user_id]
                authorize(:view_work_packages, context: @work_package.project)
              else
                authorize(:delete_work_package_watchers, context: @work_package.project)
              end

              user = User.find_by_id params[:user_id]

              Services::RemoveWatcher.new(@work_package, user).run

              status 204
            end
          end

        end
      end
    end
  end
end
