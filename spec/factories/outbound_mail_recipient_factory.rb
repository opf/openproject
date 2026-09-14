# frozen_string_literal: true

FactoryBot.define do
  factory :outbound_mail_recipient do
    sequence(:mail) { |n| "user#{n}@example.com" }
    sent_on { Date.current }
  end
end
