FactoryBot.define do
  factory :event do
    subject { "MyText" }
    read_ian { false }
    read_email { false }
    reason { :mentioned }
    context { nil }
    resource { nil }
  end
end
