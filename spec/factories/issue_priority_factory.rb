FactoryGirl.define do
  factory :priority, :class => IssuePriority do
    sequence(:name) { |i| "Priority #{i}" }
    active true
    
    factory :priority_low do
      name "Low"
    end
    
    factory :priority_normal do
      name "Normal"
    end

    factory :priority_high do
      name "High"
    end

    factory :priority_urgent do
      name "Urgent"
    end

    factory :priority_immediate do
      name "Immediate"
    end
  end
end

