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
    entity factory: :resource_planner
    principal factory: :user
    state { "requested" }
    start_date { Date.new(2026, 1, 5) }
    end_date { Date.new(2026, 1, 9) }
    allocated_time { 5 * 8 * 60 } # 5 days of 8 hours in minutes
    user_filter { [] }

    traits_for_enum :state

    trait :with_user_filter do
      principal { nil }
      transient do
        job_title_custom_field do
          UserCustomField.find_by(name: "Job title") ||
            create(:user_custom_field, :list,
                   name: "Job title",
                   possible_values: ["Developer", "Designer", "Project Manager", "Product Manager"])
        end
      end
      user_filter do
        cf = job_title_custom_field
        developer_option = cf.custom_options.find_by(value: "Developer")
        [
          {
            "attribute" => cf.column_name,
            "operator" => "=",
            "values" => [developer_option.id.to_s]
          }
        ]
      end
    end
  end
end
