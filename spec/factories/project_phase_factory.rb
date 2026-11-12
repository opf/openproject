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
  factory :project_phase, class: "Project::Phase" do
    project
    definition factory: :project_phase_definition
    active { true }

    start_date { Date.current - 2.days }
    finish_date { Date.current + 2.days }
    # use :calculate_duration trait if duration needs to take weekends and non working days into account
    duration { date_range_set? ? finish_date - start_date + 1 : nil }

    trait :skip_validate do
      to_create { |instance| instance.save(validate: false) }
    end

    trait :with_gated_definition do
      definition { association(:project_phase_definition, :with_start_gate, :with_finish_gate) }
    end

    trait :active do
      active { true }
    end

    trait :inactive do
      active { false }
    end

    # calculate duration taking weekdays and non working days into account
    trait :calculate_duration do
      duration { calculate_duration }
    end
  end
end
