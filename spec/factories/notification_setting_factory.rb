FactoryBot.define do
  factory :notification_setting do
    involved { true }
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
  end
end
