FactoryGirl.define do
  factory :default_enumeration, :class => Enumeration do
    initialize_with do
      Enumeration.find(:first, :conditions => {:type => 'Enumeration', :is_default => true}) || Enumeration.new
    end

    active true
    is_default true
    type "Enumeration"
    name "Default Enumeration"
  end

  factory :priority, :class => IssuePriority do
    sequence(:name) { |i| "Priority #{i}" }
    active true

    factory :priority_low do
      name "Low"

      # reuse existing priority with the given name
      # this prevents a validation error (name has to be unique)
      initialize_with { IssuePriority.find_or_create_by_name(name)}

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
end

