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
  # Plans a work package: a task referencing it on the given day and in the given day part, by
  # default today in the current day part, unless one of that day's tasks already refers to it.
  class AddWorkPackageService
    def initialize(user:)
      @user = user
    end

    def call(work_package:, date: user.today, day_part: nil)
      project = ProjectService.new(user).call.result
      return ServiceResult.failure(message: I18n.t("planner.errors.unavailable")) unless project
      return ServiceResult.success(message: I18n.t("planner.already_planned")) if planned?(project, work_package, date)

      create_task(work_package, date, day_part.presence || Today.new(user:, project:).current_day_part)
    end

    private

    attr_reader :user

    def create_task(work_package, date, day_part)
      CreateTaskService
        .new(user:)
        .call(subject: "##{work_package.display_id}", day_part:, date:)
        .tap { |call| call.message = added_message(date, day_part) if call.success? }
    end

    def planned?(project, work_package, date)
      task_ids = project.work_packages.where(due_date: date).pluck(:id)

      Relation.where(from_id: task_ids, to_id: work_package.id)
              .or(Relation.where(from_id: work_package.id, to_id: task_ids))
              .exists?
    end

    def added_message(date, day_part)
      day_part_name = I18n.t("planner.day_part.#{day_part}")
      return I18n.t("planner.added_to", day_part: day_part_name) if date == user.today

      I18n.t("planner.added_to_date", day_part: day_part_name, date: I18n.l(date, format: :long))
    end
  end
end
