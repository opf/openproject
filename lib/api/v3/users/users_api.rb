module API
  module V3
    module Users
      class UsersAPI < Grape::API

        resources :users do

          params do
            requires :id, desc: 'User\'s id'
          end
          namespace ':id' do

            before do
              @user = User.find(params[:id])
              model = ::API::V3::Users::UserModel.new(@user)
              @representer =  ::API::V3::Users::UserRepresenter.new(model)
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
