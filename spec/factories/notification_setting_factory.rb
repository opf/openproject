FactoryBot.define do
  factory :notification_setting do
    transient do
      all { nil } # set to true to turn all settings to true
    end

    assignee { true }
    responsible { true }
    mentioned { true }
    watched { true }
    work_package_commented { false }
    work_package_created { false }
    work_package_processed { false }
    work_package_prioritized { false }
    work_package_scheduled { false }
    news_added { false }
    news_commented { false }
    document_added { false }
    forum_messages { false }
    wiki_page_added { false }
    wiki_page_updated { false }
    membership_added { false }
    membership_updated { false }
    project { nil } # Default settings
    user

    callback(:after_build, :after_stub) do |notification_setting, evaluator|
      if evaluator.all == true
        all_boolean_settings = NotificationSetting.all_settings - NotificationSetting.date_alert_settings
        all_true = all_boolean_settings.index_with(true)
        notification_setting.assign_attributes(all_true)
      end
    end
  end
end
