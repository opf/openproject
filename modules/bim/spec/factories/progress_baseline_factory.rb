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
  factory :progress_baseline, class: 'Bim::ProgressBaseline' do
    association :ifc_model, factory: :ifc_model
    association :created_by, factory: :user

    sequence(:name) { |n| "Baseline #{n}" }
    description { "Baseline snapshot for #{name}" }
    snapshot_date { Date.current }
    total_elements { 100 }
    completed_elements { 25 }
    overall_progress { 25.0 }
    is_current { false }

    trait :current do
      is_current { true }
    end

    trait :with_statistics do
      statistics do
        {
          'by_type' => {
            'IfcWall' => { 'total' => 40, 'completed' => 10, 'progress' => 25.0 },
            'IfcDoor' => { 'total' => 30, 'completed' => 10, 'progress' => 33.33 },
            'IfcWindow' => { 'total' => 30, 'completed' => 5, 'progress' => 16.67 }
          },
          'by_status' => {
            'planned' => 50,
            'in_progress' => 25,
            'completed' => 25,
            'on_hold' => 0
          }
        }
      end
    end

    trait :empty do
      total_elements { 0 }
      completed_elements { 0 }
      overall_progress { 0.0 }
    end

    trait :half_complete do
      total_elements { 100 }
      completed_elements { 50 }
      overall_progress { 50.0 }
    end

    trait :fully_complete do
      total_elements { 100 }
      completed_elements { 100 }
      overall_progress { 100.0 }
    end
  end
end
