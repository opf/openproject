FactoryBot.define do
  factory :week_day do
    sequence :day, [1, 2, 3, 4, 5, 6, 7].cycle
    working { day < 6 }

    # hack to reuse the day if it already exists in database
    to_create do |instance|
      instance.attributes = WeekDay.find_or_create_by(instance.attributes.slice("day", "working")).attributes
      instance.instance_variable_set('@new_record', false)
    end
  end

  # Factory to create all 7 week days at once
  factory :week_days, class: 'Array' do
    # Skip the create callback to be able to use non-AR models. Otherwise FactoryBot will
    # try to call #save! on any created object.
    skip_create

    initialize_with do
      days = 1.upto(7).map { |day| create(:week_day, day:) }
      new(days)
    end
  end
end
