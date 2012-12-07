FactoryGirl.define do
  factory :tracker do
    sequence(:position) { |p| p }
    name { |a| "Tracker No. #{a.position}" }
  end

  factory :tracker_bug, :class => Tracker do
    name "Bug"
    is_in_chlog true
    position 1

    factory :tracker_feature do
      name "Feature"
      position 2
    end

    factory :tracker_support do
      name "Support"
      position 3
    end

    factory :tracker_task do
      name "Task"
      position 4
    end

    factory :tracker_with_workflow do
      sequence(:name) { |n| "Tracker #{n}" }
      sequence(:position) { |n| n }
      after :build do |t|
        t.workflows = [FactoryGirl.build(:workflow_with_default_status)]
      end
    end
  end
end
