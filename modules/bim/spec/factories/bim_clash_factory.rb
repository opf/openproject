# frozen_string_literal: true

FactoryBot.define do
  factory :bim_clash, class: 'Bim::Clash' do
    association :ifc_model, factory: :ifc_model

    sequence(:element_a_id) { |n| "element-a-#{n}" }
    sequence(:element_b_id) { |n| "element-b-#{n}" }

    clash_type { :hard }
    severity { :major }
    status { :new }

    distance { -10.5 }  # Negative indicates overlap
    overlap_volume { 100.0 }
    clash_point { { x: 100.0, y: 200.0, z: 50.0 } }

    detected_at { Time.current }
    detection_run_id { "run_#{SecureRandom.hex(4)}" }
    detection_params { { clearance_distance: 50.0 } }

    # Clash type traits
    trait :hard do
      clash_type { :hard }
      distance { -15.0 }
      overlap_volume { 150.0 }
    end

    trait :soft do
      clash_type { :soft }
      distance { 75.0 }
      overlap_volume { nil }
    end

    trait :clearance do
      clash_type { :clearance }
      distance { 30.0 }
      overlap_volume { nil }
    end

    trait :workflow do
      clash_type { :workflow }
      distance { nil }
      overlap_volume { nil }
    end

    # Severity traits
    trait :critical do
      severity { :critical }
    end

    trait :major do
      severity { :major }
    end

    trait :minor do
      severity { :minor }
    end

    # Status traits
    trait :new do
      status { :new }
    end

    trait :active do
      status { :active }
      assigned_to { association :user }
    end

    trait :approved do
      status { :approved }
      approved_by { association :user }
      approved_at { Time.current }
      approval_comment { 'Acceptable as-is' }
    end

    trait :resolved do
      status { :resolved }
      resolved_by { association :user }
      resolved_at { Time.current }
      resolution_type { :redesign }
      resolution_comment { 'Elements redesigned' }
    end

    trait :closed do
      status { :closed }
    end

    # With work package
    trait :with_work_package do
      work_package { association :work_package }
    end

    # Element type combinations
    trait :wall_vs_door do
      element_a_id { 'wall-101' }
      element_b_id { 'door-201' }
    end

    trait :wall_vs_wall do
      element_a_id { 'wall-101' }
      element_b_id { 'wall-102' }
    end

    trait :column_vs_beam do
      element_a_id { 'column-301' }
      element_b_id { 'beam-401' }
    end

    # Large clash
    trait :large_overlap do
      overlap_volume { 5000.0 }
      distance { -100.0 }
      severity { :critical }
    end

    # Stale clash (old)
    trait :stale do
      detected_at { 60.days.ago }
      status { :active }
    end

    # Recent clash
    trait :recent do
      detected_at { 1.hour.ago }
      status { :new }
    end
  end
end
