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
  factory :element_progress, class: 'Bim::ElementProgress' do
    association :ifc_model, factory: :ifc_model
    association :updated_by, factory: :user

    sequence(:element_id) { |n| "element-#{n}" }
    element_type { 'IfcWall' }
    sequence(:element_name) { |n| "Wall #{n}" }
    status { :planned }
    percent_complete { 0 }
    baseline { nil } # Default to current progress

    trait :planned do
      status { :planned }
      percent_complete { 0 }
      actual_start { nil }
      actual_finish { nil }
    end

    trait :in_progress do
      status { :in_progress }
      percent_complete { 50 }
      actual_start { 5.days.ago.to_date }
      actual_finish { nil }
    end

    trait :completed do
      status { :completed }
      percent_complete { 100 }
      actual_start { 10.days.ago.to_date }
      actual_finish { Date.current }
    end

    trait :on_hold do
      status { :on_hold }
      percent_complete { 30 }
      actual_start { 5.days.ago.to_date }
      actual_finish { nil }
    end

    trait :with_baseline do
      association :baseline, factory: :progress_baseline
    end

    trait :with_work_package do
      association :work_package, factory: :work_package
    end

    trait :with_schedule do
      planned_start { 10.days.ago.to_date }
      planned_finish { 5.days.from_now.to_date }
    end

    trait :delayed do
      status { :in_progress }
      planned_start { 20.days.ago.to_date }
      planned_finish { 5.days.ago.to_date }
      actual_start { 20.days.ago.to_date }
      actual_finish { nil }
    end

    trait :ahead_of_schedule do
      status { :completed }
      planned_start { 10.days.ago.to_date }
      planned_finish { 5.days.from_now.to_date }
      actual_start { 10.days.ago.to_date }
      actual_finish { Date.current }
      percent_complete { 100 }
    end

    trait :on_schedule do
      status { :completed }
      planned_start { 10.days.ago.to_date }
      planned_finish { Date.current }
      actual_start { 10.days.ago.to_date }
      actual_finish { Date.current }
      percent_complete { 100 }
    end

    # Element type variations
    trait :wall do
      element_type { 'IfcWall' }
      sequence(:element_name) { |n| "Wall #{n}" }
    end

    trait :door do
      element_type { 'IfcDoor' }
      sequence(:element_name) { |n| "Door #{n}" }
    end

    trait :window do
      element_type { 'IfcWindow' }
      sequence(:element_name) { |n| "Window #{n}" }
    end

    trait :column do
      element_type { 'IfcColumn' }
      sequence(:element_name) { |n| "Column #{n}" }
    end
  end
end
