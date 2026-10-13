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
  # default today in the current day part, unless one of that day's tasks already stands for it.
  class AddWorkPackageService
    def initialize(user:)
      @user = user
    end

    # With a note, the task says what to do about the work package, so it is added even when the
    # work package is already planned for that day.
    def call(work_package:, date: user.today, day_part: nil, note: nil, description: nil)
      project = ProjectService.new(user).call.result
      return ServiceResult.failure(message: I18n.t("planner.errors.unavailable")) unless project
      if note.blank? && planned?(project, work_package, date)
        return ServiceResult.success(message: I18n.t("planner.already_planned"))
      end

      day_part = day_part.presence || Today.new(user:, project:).current_day_part
      create_task(subject: subject_for(work_package, note), date:, day_part:, description:)
    end

    private

    attr_reader :user

    def subject_for(work_package, note)
      return note if References.ids_in(note).intersect?(References.ids_of(work_package))

      [note, "##{work_package.display_id}"].compact_blank.join(" ")
    end

    def create_task(subject:, date:, day_part:, description:)
      CreateTaskService
        .new(user:)
        .call(subject:, day_part:, date:, description:)
        .tap { |call| call.message = added_message(date, day_part) if call.success? }
    end

    def planned?(project, work_package, date)
      ids = References.ids_of(work_package)

      project.work_packages.where(due_date: date).pluck(:subject).any? { References.planned_id(it).in?(ids) }
    end

    def added_message(date, day_part)
      day_part_name = I18n.t("planner.day_part.#{day_part}")
      return I18n.t("planner.added_to", day_part: day_part_name) if date == user.today

      I18n.t("planner.added_to_date", day_part: day_part_name, date: I18n.l(date, format: :long))
    end
  end
end
