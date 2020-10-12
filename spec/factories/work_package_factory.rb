#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

FactoryBot.define do
  factory :work_package do
    transient do
      custom_values { nil }
    end

    priority
    project factory: :project_with_types
    status factory: :status
    sequence(:subject) { |n| "WorkPackage No. #{n}" }
    description { |i| "Description for '#{i.subject}'" }
    author factory: :user
    created_at { Time.now }
    updated_at { Time.now }

    callback(:after_build) do |work_package, evaluator|
      work_package.type = work_package.project.types.first unless work_package.type

      custom_values = evaluator.custom_values || {}

      if custom_values.is_a? Hash
        custom_values.each_pair do |custom_field_id, value|
          work_package.custom_values.build custom_field_id: custom_field_id, value: value
        end
      else
        custom_values.each { |cv| work_package.custom_values << cv }
      end
    end
  end

  factory :stubbed_work_package, class: WorkPackage do
    transient do
      custom_values { nil }
    end

    priority
    project { FactoryBot.build_stubbed(:project_with_types) }
    status
    sequence(:subject) { |n| "WorkPackage No. #{n}" }
    description { |i| "Description for '#{i.subject}'" }
    author factory: :user
    created_at { Time.now }
    updated_at { Time.now }

    callback(:after_stub) do |wp, arguments|
      wp.type = wp.project.types.first unless wp.type_id || arguments.instance_variable_get(:@overrides).has_key?(:type)
    end
  end
end
