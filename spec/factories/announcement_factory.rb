FactoryGirl.define do
  factory :announcement do
    text 'Announcement text'
    show_until Date.today + 14.days
    active true

    factory :active_announcement do
      active true
    end

    factory :inactive_announcement do
      active false
    end
  end
end
