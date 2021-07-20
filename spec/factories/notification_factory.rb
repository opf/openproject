FactoryBot.define do
  factory :notification do
    subject { "MyText" }
    read_ian { false }
    read_mail { false }
    read_mail_digest { false }
    reason_ian { :mentioned }
    reason_mail { :involved }
    reason_mail_digest { :watched }
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
