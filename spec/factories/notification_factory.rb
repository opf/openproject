FactoryBot.define do
  factory :notification do
    subject { "MyText" } # rubocop:disable RSpec/EmptyLineAfterSubject
    read_ian { false }
    mail_reminder_sent { false }
    mail_alert_sent { false }
    reason { :mentioned }
    recipient factory: :user
    project { association :project }
    resource { association :work_package, project: project }
    actor { nil }
    journal { nil }

    callback(:after_build) do |notification, _|
      notification.journal ||= notification.resource.journals.last
      notification.actor ||= notification.journal.try(:user)
    end
  end
end
