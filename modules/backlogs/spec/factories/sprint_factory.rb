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

FactoryBot.define do
  time_from_date = ->(date) { [date.midday, Time.zone.now].min if date }

  factory :sprint do
    sequence(:name) { |n| "Sprint #{n}" }
    project
    start_date { Time.zone.today }
    finish_date { Time.zone.today + 14.days }

    transient do
      status { nil }
      status_from_trait { nil }
    end

    callback(:after_build, :after_stub) do |sprint, context|
      if context.status.in?(Sprint.statuses)
        fail ArgumentError, "Use trait :#{context.status} instead of setting status", caller
      elsif context.status
        fail ArgumentError, "Use trait :in_planning, :active or :completed instead of setting status", caller
      end

      sprint.status =
        if sprint.completed_at? then "completed"
        elsif sprint.started_at? then "active"
        else "in_planning"
        end

      from_trait = context.status_from_trait
      next if sprint.status == (from_trait || "in_planning")

      if from_trait
        fail ArgumentError, "Trait :#{from_trait} contradicts status #{sprint.status} from status timestamps", caller
      else
        fail ArgumentError, "Use trait :#{sprint.status} for a sprint with these status timestamps", caller
      end
    end

    callback(:after_stub) { |sprint, _context| sprint.clear_status_change } # stubs should not be dirty

    trait :in_planning do
      status_from_trait { "in_planning" }
    end

    trait :active do
      status_from_trait { "active" }
      started_at { time_from_date.call(start_date) }
    end

    trait :completed do
      status_from_trait { "completed" }
      start_date { Time.zone.today - 14.days }
      finish_date { Time.zone.today }
      started_at { time_from_date.call(start_date) }
      completed_at { time_from_date.call(finish_date) }
    end
  end
end
