Rails.application.routes.draw do
  namespace 'two_factor_authentication' do
    get :request, to: 'authentication#request_otp'
    post :confirm, to: 'authentication#confirm_otp'
    post :retry, to: 'authentication#retry'
    get :backup_code, to: 'authentication#enter_backup_code'
    post :backup_code, to: 'authentication#verify_backup_code'

    get :settings, to: 'two_factor_settings#show', as: 'settings_2fa'
    post :settings, to: 'two_factor_settings#update', as: 'update_settings_2fa'

    # Request a challenge for WebAuthn
    get :webauthn_challenge, to: 'authentication#webauthn_challenge', as: 'webauthn_challenge'
  end

  scope 'two_factor_authentication' do # Avoids adding the namespace prefix
    # forced registration
    scope 'device_registration', controller: 'two_factor_authentication/forced_registration/two_factor_devices' do
      get :new, action: :new, as: 'new_forced_2fa_device'
      post :register, action: :register, as: 'register_forced_2fa_device'
      match '/:device_id/confirm', action: :confirm, via: %i[get post], as: 'confirm_forced_2fa_device'

      # Request a challenge for WebAuthn
      get :webauthn_challenge
    end
  end

  resources :users, only: [] do
    member do
      resources :two_factor_devices,
                param: :device_id,
                controller: 'two_factor_authentication/users/two_factor_devices',
                as: 'user_2fa_devices',
                only: %i[new create destroy] do
        # Register new device ( 'create' )
        post :register, on: :collection

        # Delete all devices
        post :delete_all, on: :collection

        # Make default
        post :make_default, on: :member

        # Request a challenge for WebAuthn
        get :webauthn_challenge, on: :collection
      end
    end
  end

  scope 'my' do
    resource :backup_codes,
             controller: 'two_factor_authentication/my/backup_codes',
             as: 'my_2fa_backup_codes',
             only: %i[show create]

    resource :remember_cookie,
             controller: 'two_factor_authentication/my/remember_cookie',
             as: 'my_2fa_remember_cookie',
             only: [:destroy]

    resources :two_factor_devices,
              controller: 'two_factor_authentication/my/two_factor_devices',
              param: :device_id,
              as: 'my_2fa_devices',
              only: %i[index new destroy] do
      # Register new device ( 'create' )
      post :register, on: :collection

      # Confirm token flow for new devices
      get :confirm, on: :member
      post :confirm, on: :member

      # Make a device a default
      post :make_default, on: :member

      # Request a challenge for WebAuthn
      get :webauthn_challenge, on: :collection
    end
  end
end
