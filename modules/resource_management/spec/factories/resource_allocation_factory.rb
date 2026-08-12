# frozen_string_literal: true

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
  factory :resource_allocation, class: "ResourceAllocation" do
    entity factory: :work_package
    principal factory: :user
    requested_by factory: :user
    reviewed_by { requested_by }
    state { "allocated" }
    start_date { Date.new(2026, 1, 5) }
    end_date { Date.new(2026, 1, 9) }
    allocated_time { 5 * 8 * 60 } # 5 days of 8 hours in minutes
    user_filter { [] }
    principal_explicit { true }

    traits_for_enum :state

    trait :with_user_filter do
      principal_explicit { false }
      principal { nil }
      filter_name { "Full stack Developer (DE-EN)" }
      transient do
        job_title_custom_field do
          UserCustomField.find_by(name: "Job title") ||
            create(:user_custom_field, :list,
                   name: "Job title",
                   possible_values: ["Developer", "Designer", "Project Manager", "Product Manager"])
        end
        spoken_language_custom_field do
          UserCustomField.find_by(name: "Spoken language") ||
            create(:user_custom_field, :list,
                   name: "Spoken language",
                   multi_value: true,
                   possible_values: %w[German English French Spanish Italian Dutch Portuguese Polish])
        end
      end
      # Build real UserQuery filter objects (not hashes): the serialization
      # coder dumps via `filter.field`, so it only accepts filter instances.
      # The filter matches developers who speak German or English ("DE-EN"),
      # leaving the other languages as non-matching values to test against.
      user_filter do
        job_title = job_title_custom_field
        language = spoken_language_custom_field
        developer_option = job_title.custom_options.find_by(value: "Developer")
        language_options = language.custom_options.where(value: %w[German English])

        query = UserQuery.new
        query.where(job_title.column_name, "=", [developer_option.id.to_s])
        query.where(language.column_name, "=", language_options.map { |option| option.id.to_s })
        query.filters
      end
    end
  end
end
