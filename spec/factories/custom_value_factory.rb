FactoryGirl.define do
  factory :custom_value do
    custom_field
    value ""

    factory :principal_custom_value do
      custom_field :factory => :user_custom_field
      customized :factory => :user
    end

    factory :issue_custom_value do
      custom_field :factory => :issue_custom_field
      customized :factory => :issue
    end
  end
end
