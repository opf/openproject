class API < Grape::API
  format :json

  get '/' do
    "I work!"
  end
end
