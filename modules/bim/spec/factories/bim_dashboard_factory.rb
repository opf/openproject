# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See COPYRIGHT and LICENSE files for more details.
#++

FactoryBot.define do
  factory :bim_dashboard, class: 'Bim::Dashboard' do
    association :project, factory: :project
    association :user, factory: :user

    sequence(:name) { |n| "BIM Dashboard #{n}" }
    description { "Dashboard for tracking BIM metrics" }
    is_default { false }
    is_public { false }
    layout_config { { cols: 12, rowHeight: 100 } }
    settings { {} }

    trait :default do
      is_default { true }
      is_public { true }
      name { "Default BIM Dashboard" }
    end

    trait :public do
      is_public { true }
    end

    trait :with_widgets do
      after(:create) do |dashboard|
        create_list(:bim_dashboard_widget, 3, dashboard: dashboard)
      end
    end
  end
end
