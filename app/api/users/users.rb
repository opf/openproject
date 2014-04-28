module Users
  class API < Grape::API

    resources :users do
      get do
        "users"
      end
    end

  end
end
