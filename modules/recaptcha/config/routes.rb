OpenProject::Application::routes.draw do

  namespace 'recaptcha' do
    get :settings, to: 'admin#show'
    post :settings, to: 'admin#update'

    get :request, to: 'request#perform', as: 'request'
    post :verify, to: 'request#verify', as: 'verify'
  end
end
