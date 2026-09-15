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
  factory :bim_model_comparison, class: 'Bim::ModelComparison' do
    model1 { association :ifc_model }
    model2 { association :ifc_model, project: model1.project }
    comparison_type { :version }
    status { :pending }
    added_count { 0 }
    deleted_count { 0 }
    modified_count { 0 }
    unchanged_count { 0 }
    changes_data { {} }
    statistics { {} }
    comparison_options { {} }

    trait :pending do
      status { :pending }
    end

    trait :completed do
      status { :completed }
      completed_at { Time.current }
      comparison_time { 1.5 }
    end

    trait :approved do
      status { :approved }
      completed_at { Time.current }
      approved_at { Time.current }
      approved_by { association :user }
      status_comment { 'Changes approved for implementation' }
    end

    trait :rejected do
      status { :rejected}
      completed_at { Time.current }
      approved_at { Time.current }
      approved_by { association :user }
      status_comment { 'Changes not acceptable' }
    end

    trait :version_comparison do
      comparison_type { :version }
    end

    trait :baseline_comparison do
      comparison_type { :baseline }
    end

    trait :federated_comparison do
      comparison_type { :federated }
    end

    trait :with_changes do
      added_count { 10 }
      deleted_count { 5 }
      modified_count { 3 }
      unchanged_count { 82 }
      changes_data do
        {
          'added' => [
            {
              'element_id' => 'new-wall-1',
              'element' => {
                'properties' => { 'type' => 'IfcWall', 'name' => 'New Wall 1' },
                'geometry' => { 'hash' => 'abc123' }
              }
            }
          ],
          'deleted' => [
            {
              'element_id' => 'old-door-1',
              'element' => {
                'properties' => { 'type' => 'IfcDoor', 'name' => 'Old Door 1' },
                'geometry' => { 'hash' => 'def456' }
              }
            }
          ],
          'modified' => [
            {
              'element_id' => 'wall-101',
              'element_before' => {
                'properties' => { 'type' => 'IfcWall', 'height' => '3000' }
              },
              'element_after' => {
                'properties' => { 'type' => 'IfcWall', 'height' => '3500' }
              },
              'changes' => [
                {
                  'type' => 'property',
                  'property' => 'height',
                  'old_value' => '3000',
                  'new_value' => '3500'
                }
              ]
            }
          ],
          'unchanged' => []
        }
      end
      statistics do
        {
          'total_elements_model1' => 90,
          'total_elements_model2' => 100,
          'change_percentage' => 18.0,
          'geometry_changes' => 2,
          'property_changes' => 5,
          'type_changes' => 0,
          'by_type' => {
            'IfcWall' => { 'added' => 8, 'deleted' => 2, 'modified' => 2 },
            'IfcDoor' => { 'added' => 2, 'deleted' => 3, 'modified' => 1 }
          }
        }
      end
    end

    trait :no_changes do
      added_count { 0 }
      deleted_count { 0 }
      modified_count { 0 }
      unchanged_count { 100 }
      changes_data { { 'added' => [], 'deleted' => [], 'modified' => [], 'unchanged' => [] } }
    end

    trait :major_changes do
      added_count { 50 }
      deleted_count { 30 }
      modified_count { 20 }
      unchanged_count { 100 }
      statistics do
        {
          'change_percentage' => 50.0
        }
      end
    end

    trait :geometry_changes do
      modified_count { 10 }
      changes_data do
        {
          'modified' => [
            {
              'element_id' => 'wall-101',
              'changes' => [
                {
                  'type' => 'geometry',
                  'description' => 'Geometry changed',
                  'details' => {
                    'position_changed' => true,
                    'position_delta' => { 'x' => 100, 'y' => 0, 'z' => 0 }
                  }
                }
              ]
            }
          ]
        }
      end
    end

    trait :property_changes do
      modified_count { 10 }
      changes_data do
        {
          'modified' => [
            {
              'element_id' => 'wall-101',
              'changes' => [
                {
                  'type' => 'property',
                  'property' => 'FireRating',
                  'old_value' => '60min',
                  'new_value' => '90min'
                }
              ]
            }
          ]
        }
      end
    end

    trait :recent do
      created_at { 1.day.ago }
    end

    trait :stale do
      created_at { 40.days.ago }
    end
  end
end
