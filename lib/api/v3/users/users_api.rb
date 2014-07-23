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
              @user  = User.find(params[:id])
              @model = UserModel.new(@user)
            end

            get do
              UserRepresenter.new(@model)
            end

          end

        end

      end
    end
  end
end
