# frozen_string_literal: true

FactoryBot.define do
  factory :bim_comment_mention, class: 'Bim::CommentMention' do
    association :comment, factory: :bcf_comment
    association :user

    trait :recent do
      created_at { 1.hour.ago }
    end

    trait :old do
      created_at { 1.week.ago }
    end
  end

  factory :bim_viewer_presence, class: 'Bim::ViewerPresence' do
    association :ifc_model, factory: :bim_ifc_model
    association :user

    last_seen_at { Time.current }
    camera_position { { eye: [0, 0, 10], look: [0, 0, 0], up: [0, 1, 0] } }

    trait :active do
      last_seen_at { 2.minutes.ago }
    end

    trait :stale do
      last_seen_at { 10.minutes.ago }
    end

    trait :inactive do
      last_seen_at { 1.hour.ago }
    end

    trait :with_camera do
      camera_position { { eye: [5, 5, 5], look: [0, 0, 0], up: [0, 1, 0] } }
    end
  end

  # Enhanced BCF Comment factory (extending existing)
  factory :bcf_comment_with_reactions, parent: :bcf_comment do
    status { 'question' }
    reactions do
      {
        '👍' => [1, 2, 3],
        '✅' => [1]
      }
    end

    trait :with_status_issue do
      status { 'issue' }
    end

    trait :with_status_resolved do
      status { 'resolved' }
    end

    trait :with_many_reactions do
      reactions do
        {
          '👍' => [1, 2, 3, 4, 5],
          '👎' => [6, 7],
          '✅' => [1, 3],
          '❓' => [8]
        }
      end
    end
  end
end
