FactoryBot.define do
  factory :notification do
    subject { "MyText" } # rubocop:disable RSpec/EmptyLineAfterSubject
    read_ian { false }
    sent_mail { false }
    reason { :mentioned }
    recipient factory: :user
    project { association :project }
    resource { association :work_package, project: project }
    actor { journal.try(:user) }

    transient { journal }

    callback(:after_create) do |notification, evaluator|
      notification.journal = evaluator.journal || notification.work_package.journals.last
      notification.save!
    end
  end
end
