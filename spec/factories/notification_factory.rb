FactoryBot.define do
  factory :notification do
    subject { "MyText" }
    read_ian { false }
    read_email { false }
    reason { :mentioned }
    recipient factory: :user
    project { association :project }
    resource { association :work_package, project: project }
    journal { association :work_package_journal, journable: resource }
    actor { journal.try(:user) }
  end
end
