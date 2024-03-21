FactoryBot.define do
  factory :two_factor_authentication_device_sms, class: '::TwoFactorAuthentication::Device::Sms' do
    user
    channel { :sms }
    active { true }
    default { true }
    phone_number { '+49 123456789' }
    identifier { 'Phone number (+49 123456789)' }

    transient do
      make_default { false }
    end

    callback(:after_create) do |device, evaluator|
      device.make_default! if evaluator.make_default
    end
  end

  factory :two_factor_authentication_device_totp, class: '::TwoFactorAuthentication::Device::Totp' do
    user
    channel { :totp }
    active { true }
    default { true }
    identifier { 'TOTP device' }

    transient do
      make_default { false }
    end

    callback(:after_create) do |device, evaluator|
      device.make_default! if evaluator.make_default
    end
  end

  factory :two_factor_authentication_device_webauthn, class: '::TwoFactorAuthentication::Device::Webauthn' do
    user
    channel { :webauthn }
    active { true }
    default { true }
    identifier { 'WebAuthn device' }

    webauthn_external_id { "foo" }
    webauthn_public_key { "bar" }

    transient do
      make_default { false }
    end

    callback(:after_create) do |device, evaluator|
      # Ensure user has a webauthn id
      if device.user.webauthn_id.blank?
        device.user.update!(webauthn_id: WebAuthn.generate_user_id)
      end

      # Generate Fake Credential, see https://github.com/cedarcode/webauthn-ruby/blob/master/spec/spec_helper.rb#L26

      device.make_default! if evaluator.make_default
    end
  end
end
