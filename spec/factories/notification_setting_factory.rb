FactoryBot.define do
  factory :notification_setting do
    all { false }
    involved { true }
    mentioned { true }
    watched { true }
    work_package_commented { false }
    work_package_created { false }
    work_package_processed { false }
    work_package_prioritized { false }
    work_package_scheduled { false }
    project { nil } # Default settings
    user
  end
end
