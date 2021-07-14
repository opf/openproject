FactoryBot.define do
  factory :notification_setting do
    channel { :mail }
    all { false }
    involved { true }
    mentioned { true }
    watched { true }
    project { nil } # Default settings
    user

    factory :mail_notification_setting do
      channel { :mail }
    end

    factory :mail_digest_notification_setting do
      channel { :mail_digest }
    end

    factory :in_app_notification_setting do
      channel { :in_app }
    end
  end
end
