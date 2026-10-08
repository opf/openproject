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
  # Plans a work package for today: a task referencing it in the current day part, unless one of
  # today's tasks already refers to it.
  class AddWorkPackageService
    def initialize(user:)
      @user = user
    end

    def call(work_package:)
      today = Today.for(user)
      return ServiceResult.failure(message: I18n.t("planner.errors.unavailable")) unless today
      return ServiceResult.success(message: I18n.t("planner.already_planned")) if planned?(today, work_package)

      day_part = today.current_day_part
      CreateTaskService
        .new(user:)
        .call(subject: "##{work_package.display_id}", day_part:)
        .tap { |call| call.message = added_message(day_part) if call.success? }
    end

    private

    attr_reader :user

    def planned?(today, work_package)
      task_ids = today.work_packages.map(&:id)

      Relation.where(from_id: task_ids, to_id: work_package.id)
              .or(Relation.where(from_id: work_package.id, to_id: task_ids))
              .exists?
    end

    def added_message(day_part)
      I18n.t("planner.added_to", day_part: I18n.t("planner.day_part.#{day_part}"))
    end
  end
end
