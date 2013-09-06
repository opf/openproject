FactoryGirl.define do
  factory :meeting_journal do
    created_at Time.now
    sequence(:version) {|n| n}

    factory :meeting_content_journal, class: Journal do
      journable_type "MeetingContent"
      activity_type "meetings"
      data FactoryGirl.build(:journal_meeting_content_journal)
    end
  end
end
