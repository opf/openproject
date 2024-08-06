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
  factory :query do
    project
    user factory: :user
    include_subprojects { Setting.display_subprojects_work_packages? }
    show_hierarchies { false }
    display_sums { false }
    sequence(:name) { |n| "Query #{n}" }

    factory :public_query do
      public { true }
      sequence(:name) { |n| "Public query #{n}" }
    end

    factory :private_query do
      public { false }
      sequence(:name) { |n| "Private query #{n}" }
    end

    factory :global_query do
      project { nil }
      public { true }
      sequence(:name) { |n| "Global query #{n}" }
    end

    factory :query_with_view_work_packages_table do
      sequence(:name) { |n| "Work packages query #{n}" }

      callback(:after_create) do |query|
        create(:view_work_packages_table, query:)
      end
    end

    factory :query_with_view_team_planner do
      sequence(:name) { |n| "Team planner query #{n}" }

      callback(:after_create) do |query|
        create(:view_team_planner, query:)
      end
    end

    factory :query_with_view_work_packages_calendar do
      sequence(:name) { |n| "Calendar query #{n}" }

      callback(:after_create) do |query|
        create(:view_work_packages_calendar, query:)
      end
    end

    factory :query_with_view_gantt do
      sequence(:name) { |n| "Gantt query #{n}" }

      callback(:after_create) do |query|
        create(:view_gantt, query:)
      end
    end

    factory :query_with_view_bim do
      sequence(:name) { |n| "Bim query #{n}" }

      callback(:after_create) do |query|
        create(:view_bim, query:)
      end
    end

    callback(:after_build) { |query| query.add_default_filter }
  end
end
