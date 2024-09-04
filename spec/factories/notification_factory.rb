FactoryBot.define do
  factory :notification do
    subject { "MyText" }
    read_ian { false }
    mail_reminder_sent { false }
    mail_alert_sent { false }
    reason { :mentioned }
    recipient factory: :user
    resource { association :work_package }

    trait :for_milestone do
      resource { association :work_package, :is_milestone }
    end
    # journal and actor are not listed by intend.
    # They will be set in the after_build callback.
    # But not listing them allows to identify if they have been provided, even if nil has been provided.

    callback(:after_build) do |notification, evaluator|
      # Default the journal and the actor associations but only if:
      # * it is not a date alert
      # * the values haven't been overridden (including setting them to nil).
      unless notification.reason_date_alert_due_date? || notification.reason_date_alert_start_date?
        notification.journal ||= notification.resource.journals.last unless evaluator.overrides?(:journal)
        notification.actor ||= notification.journal.try(:user) unless evaluator.overrides?(:actor)
      end
    end
  end
end
