FactoryBot.define do
  factory :event do
    subject { "MyText" }
    read_iam { false }
    read_email { false }
    reason { :mentioned }
    context { nil }
    resource { nil }
  end
end
