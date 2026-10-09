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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

FactoryBot.define do
  factory :time_entry do
    user
    entity factory: :work_package
    spent_on { Time.zone.today }
    activity factory: :time_entry_activity
    hours { 1.0 }
    logged_by { user }

    after(:build) do |time_entry|
      time_entry.project ||= time_entry.entity.project
    end

    after(:create) do |time_entry|
      if time_entry.entity.present?
        time_entry.update(project: time_entry.entity.project)
      end

      # ensure user is member of project
      unless Member.exists?(principal: time_entry.user, project: time_entry.project)
        role = create(:project_role, permissions: [:view_project])
        create(:member, principal: time_entry.user, project: time_entry.project, roles: [role])
      end
    end

    trait :with_start_and_end_time do
      time_zone { "Asia/Tokyo" }
      start_time { 390 } # 6:30 AM
      hours { 2.5 }
    end

    trait :on_meeting do
      entity factory: :meeting
    end
  end
end
