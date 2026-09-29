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
  # Prefer `:wp_custom_field` / `:string_wp_custom_field` etc. This factory remains for the many
  # call sites that still name `:work_package_custom_field`.
  factory :work_package_custom_field, class: "WorkPackageCustomField" do
    activatable_on_types

    transient do
      default_locales { nil }
      projects { [] }
    end

    sequence(:name) { |n| "Custom Field Nr. #{n}" }
    regexp { "" }
    is_required { false }
    min_length { false }
    default_value { "" }
    max_length { false }
    editable { true }
    possible_values { "" }
    admin_only { false }
    field_format { "bool" }

    after(:create) do |custom_field, evaluator|
      evaluator.projects.each do |project|
        project.work_package_custom_fields << custom_field
      end
    end
  end
end
