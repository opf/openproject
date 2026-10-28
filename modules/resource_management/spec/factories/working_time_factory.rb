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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

# Factories bypass the services that keep the stored resource allocation
# schedules current, so the affected schedules are rebuilt here.
FactoryBot.modify do
  factory :user_working_hours do
    after(:create) do |working_hours|
      ResourceAllocations::UpdateScheduleService.new.call(users: [working_hours.user], from: nil)
    end
  end

  factory :user_non_working_time do
    after(:create) do |non_working_time|
      ResourceAllocations::UpdateScheduleService.new.call(users: [non_working_time.user], from: nil)
    end
  end

  factory :non_working_day do
    after(:create) do |non_working_day|
      covering = ResourceAllocation.allocated.where(start_date: ..non_working_day.date, end_date: non_working_day.date..)
      users = User.where(id: covering.select(:principal_id)).to_a

      ResourceAllocations::UpdateScheduleService.new.call(users:, from: nil)
    end
  end
end
