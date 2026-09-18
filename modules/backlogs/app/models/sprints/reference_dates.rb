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

# The interval a sprint's reports cover: when it actually began and how far it has run.
#
# A sprint that was started or completed reports from those moments rather than from the
# dates it was planned with, and one still running reports up to now once it has overrun.
module Sprints
  class ReferenceDates
    def initialize(sprint)
      @sprint = sprint
    end

    def start
      return sprint.started_at if sprint.started_at?

      sprint.start_date.in_time_zone.beginning_of_day
    end

    def finish
      return sprint.completed_at if sprint.completed_at?

      scheduled_finish = sprint.finish_date.in_time_zone.end_of_day

      return scheduled_finish unless sprint.started_at?

      [scheduled_finish, Time.zone.now].max
    end

    # What the sprint was planned with, which the guideline keeps pointing at even when the
    # sprint overruns.
    def scheduled_finish
      sprint.finish_date.in_time_zone.end_of_day
    end

    private

    attr_reader :sprint
  end
end
