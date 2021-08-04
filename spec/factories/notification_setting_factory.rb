FactoryBot.define do
  factory :notification_setting do
    channel { :mail }
    all { false }
    involved { true }
    mentioned { true }
    watched { true }
    work_package_commented { false }
    work_package_created { false }
    work_package_processed { false }
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
