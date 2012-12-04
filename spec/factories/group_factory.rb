FactoryGirl.define do
  factory :group do
    # groups have lastnames? hmm...
    sequence(:lastname) { |g| "Group #{g}" }
  end
end
