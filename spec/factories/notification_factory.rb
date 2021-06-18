FactoryBot.define do
  factory :notification do
    subject { "MyText" }
    read_ian { false }
    read_email { false }
    reason { :mentioned }
    recipient factory: :user
    context factory: :project
    resource factory: :work_package_journal
  end
end
