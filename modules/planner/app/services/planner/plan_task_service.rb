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

module Planner
  # Moves a task within the user's days: to a day part today, to today keeping its day part,
  # to tomorrow, or out of the plan by clearing its dates.
  class PlanTaskService
    TARGETS = (DayPartField::DAY_PARTS.map(&:to_s) + %w[today tomorrow remove]).freeze

    def initialize(user:, work_package:)
      @user = user
      @work_package = work_package
    end

    def call(to:)
      to = to.to_s
      return ServiceResult.failure(result: work_package, message: I18n.t("planner.errors.unknown_target")) unless to.in?(TARGETS)

      WorkPackages::UpdateService.new(user:, model: work_package).call(**attributes_for(to))
    end

    private

    attr_reader :user, :work_package

    def attributes_for(to)
      case to
      when "today" then dates(user.today)
      when "tomorrow" then dates(user.today + 1)
      when "remove" then dates(nil)
      else dates(user.today).merge(DayPartField.find.attributes_for(to))
      end
    end

    def dates(date) = { start_date: date, due_date: date }
  end
end
