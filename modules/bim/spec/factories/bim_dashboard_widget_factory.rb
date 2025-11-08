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
  factory :bim_dashboard_widget, class: 'Bim::DashboardWidget' do
    association :dashboard, factory: :bim_dashboard

    widget_type { :model_count }
    title { nil } # Will use default title
    description { nil }
    position { { x: 0, y: 0 } }
    size { { width: 4, height: 3 } }
    config { {} }
    cached_data { {} }
    cached_at { nil }
    refresh_interval { nil }

    trait :model_count do
      widget_type { :model_count }
    end

    trait :clash_summary do
      widget_type { :clash_summary }
    end

    trait :issue_trend do
      widget_type { :issue_trend }
      size { { width: 6, height: 4 } }
    end

    trait :progress_chart do
      widget_type { :progress_chart }
      size { { width: 6, height: 4 } }
    end

    trait :kpi_card do
      widget_type { :kpi_card }
      size { { width: 3, height: 2 } }
    end

    trait :with_cached_data do
      cached_data { { total: 10, recent: 3 } }
      cached_at { Time.current }
    end

    trait :with_auto_refresh do
      refresh_interval { 300 } # 5 minutes
    end
  end
end
