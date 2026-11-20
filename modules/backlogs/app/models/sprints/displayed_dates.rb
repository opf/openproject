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

module Sprints
  class DisplayedDates
    delegate :any?, to: :range

    def initialize(sprint)
      @sprint = sprint
    end

    def actual_start
      sprint.started_at unless sprint.in_planning?
    end

    def actual_finish
      sprint.completed_at if sprint.completed?
    end

    def start = actual_start || sprint.start_date

    def finish = actual_finish || sprint.finish_date

    def start_planned? = actual_start.nil?

    def finish_planned? = actual_finish.nil?

    def range = [start, finish]

    def actual_range = [actual_start, actual_finish]

    def planned_range = [sprint.start_date, sprint.finish_date]

    def actual? = actual_range.any?

    def planned? = planned_range.any?

    private

    attr_reader :sprint
  end
end
