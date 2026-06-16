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

module Backlogs::Sprints
  class StartContract < ::BaseContract
    validate :validate_permission
    validate :validate_status_in_planning
    validate :validate_dates_present
    validate :validate_no_other_active_sprint

    def self.can_start_or_complete?(user:, sprint:)
      user.allowed_in_project?(:start_complete_sprint, sprint.project)
    end

    def self.can_start?(user:, sprint:, project:)
      can_start_or_complete?(user:, sprint:) &&
        user.allowed_in_project?(:show_board_views, project)
    end

    private

    def validate_permission
      return if self.class.can_start_or_complete?(user:, sprint: model)

      errors.add :base, :error_unauthorized
    end

    def validate_status_in_planning
      return if model.in_planning?

      errors.add :status, :must_be_in_planning
    end

    def validate_dates_present
      return unless model.in_planning?
      return if model.start_date? && model.finish_date?

      errors.add :base, :dates_required
    end

    def validate_no_other_active_sprint
      return unless model.in_planning?
      return unless Sprint.where(project: model.project).active.where.not(id: model.id).exists?

      errors.add :status, :only_one_active_sprint_allowed
    end
  end
end
