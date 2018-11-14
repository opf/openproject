FactoryBot.define do
  factory :two_factor_authentication_device_sms, class: ::TwoFactorAuthentication::Device::Sms do
    user
    channel :sms
    active true
    default true
    phone_number '+49 123456789'
    identifier 'Phone number (+49 123456789)'

    transient do
      make_default false
    end

    callback(:after_create) do |device, evaluator|
      device.make_default! if evaluator.make_default
    end
  end
end

FactoryBot.define do
  factory :two_factor_authentication_device_totp, class: ::TwoFactorAuthentication::Device::Totp do
    user
    channel :totp
    active true
    default true
    identifier 'TOTP device'

    transient do
      make_default false
    end

    callback(:after_create) do |device, evaluator|
      device.make_default! if evaluator.make_default
    end
  end
end
