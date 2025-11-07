# frozen_string_literal: true

FactoryBot.define do
  factory :bim_saved_view, class: 'Bim::SavedView' do
    association :ifc_model, factory: :ifc_model
    association :user, factory: :user

    sequence(:name) { |n| "Saved View #{n}" }
    description { 'A saved camera view' }

    camera_eye { [10.0, 20.0, 30.0] }
    camera_look { [0.0, 0.0, 0.0] }
    camera_up { [0.0, 1.0, 0.0] }
    projection { 'perspective' }
    is_public { false }

    trait :public_view do
      is_public { true }
    end

    trait :orthogonal do
      projection { 'orthogonal' }
    end

    trait :top_view do
      camera_eye { [0.0, 100.0, 0.0] }
      camera_look { [0.0, 0.0, 0.0] }
      camera_up { [0.0, 0.0, -1.0] }
      projection { 'orthogonal' }
    end

    trait :isometric do
      camera_eye { [50.0, 50.0, 50.0] }
      camera_look { [0.0, 0.0, 0.0] }
      camera_up { [0.0, 1.0, 0.0] }
      projection { 'perspective' }
    end
  end
end
