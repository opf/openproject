#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

FactoryBot.define do
  factory :work_package do
    transient do
      custom_values { nil }
      days { WorkPackages::Shared::Days.for(self) }
      journals { nil }
      now { Time.zone.now }
    end

    priority
    project factory: :project_with_types
    status
    sequence(:subject) { |n| "WorkPackage No. #{n}" }
    description { |i| "Description for '#{i.subject}'" }
    author factory: :user
    created_at { now }
    updated_at { now }
    start_date do
      # derive start date if due date and duration were provided
      next unless %i[due_date duration].all? { |field| __override_names__.include?(field) }

      due_date && duration && days.start_date(due_date.to_date, duration)
    end
    due_date do
      # derive due date if start date and duration were provided
      next unless %i[start_date duration].all? { |field| __override_names__.include?(field) }

      start_date && duration && days.due_date(start_date.to_date, duration)
    end
    duration { days.duration(start_date&.to_date, due_date&.to_date) }

    trait :is_milestone do
      type factory: :type_milestone
    end

    # Using this trait, the work package and its journal will appear to have been created
    # in the past (at the time of the created_at attribute).
    trait :created_in_past do
      updated_at { created_at }

      callback(:after_create) do |work_package|
        work_package.journals.first.update_columns(created_at: work_package.created_at,
                                                   updated_at: work_package.created_at,
                                                   validity_period: work_package.created_at..Float::INFINITY)
      end
    end

    callback(:after_build) do |work_package, evaluator|
      work_package.type = work_package.project.types.first unless work_package.type

      custom_values = evaluator.custom_values || {}

      if custom_values.is_a? Hash
        custom_values.each_pair do |custom_field_id, values|
          Array(values).each do |value|
            work_package.custom_values.build custom_field_id:, value:
          end
        end
      else
        custom_values.each { |cv| work_package.custom_values << cv }
      end
    end

    callback(:after_stub) do |wp, evaluator|
      unless wp.type_id || evaluator.overrides?(:type) || wp.project.nil?
        wp.type = wp.project.types.first
      end
    end

    callback(:after_create) do |work_package, evaluator|
      if evaluator.journals.present?
        work_package.journals.destroy_all

        evaluator.journals.each_with_index do |(timestamp, attributes), version|
          work_package_attributes = work_package.attributes.except("id")

          journal_attributes = attributes
                                 .extract!(*Journal.attribute_names.map(&:to_sym) + %i[user])
                                 .reverse_merge(journable: work_package,
                                                created_at: timestamp,
                                                updated_at: timestamp,
                                                user: work_package.author,
                                                version: version + 1)

          data_attributes = work_package_attributes
                              .extract!(*Journal::WorkPackageJournal.attribute_names)
                              .symbolize_keys
                              .merge(attributes)

          create(:work_package_journal,
                 **journal_attributes,
                 data: build(:journal_work_package_journal, data_attributes))
        end

        work_package.journals.reload

        work_package.update_columns(created_at: work_package.journals.minimum(:created_at),
                                    updated_at: work_package.journals.maximum(:updated_at))
      end
    end

    set_done_ratios = ->(work_package, _evaluator) do
      if work_package.estimated_hours.present? &&
          work_package.remaining_hours.present? &&
          work_package.done_ratio.nil? &&
          work_package.estimated_hours >= work_package.remaining_hours
        work_package.done_ratio = (work_package.estimated_hours - work_package.remaining_hours) \
          / work_package.estimated_hours.to_f * 100
      end
      if work_package.derived_estimated_hours.present? &&
          work_package.derived_remaining_hours.present? &&
          work_package.derived_done_ratio.nil? &&
          work_package.derived_estimated_hours >= work_package.derived_remaining_hours
        work_package.derived_done_ratio = (work_package.derived_estimated_hours - work_package.derived_remaining_hours) \
          / work_package.derived_estimated_hours.to_f * 100
      end
    end

    callback(:after_build, &set_done_ratios)
    callback(:after_stub, &set_done_ratios)

    # force done_ratio in status-based mode if given done_ratio is different from status default
    callback(:after_create) do |work_package, evaluator|
      next unless WorkPackage.use_status_for_done_ratio?
      next unless evaluator.__override_names__.include?(:done_ratio)

      if work_package.read_attribute(:done_ratio) != evaluator.done_ratio
        work_package.update_column(:done_ratio, evaluator.done_ratio)
      end
    end
  end
end
