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

    # The in_planning status is already validated. If it's not in_planning,
    # stop running the rest of validations in order to avoid stacking error messages.
    with_options if: -> { model.in_planning? } do
      validate :validate_dates_present
      validate :validate_only_one_active_sprint, unless: -> { model.allow_multiple_active_sprints? }
      validate :validate_not_receiving_shared_sprints
    end

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
      return if model.start_date? && model.finish_date?

      errors.add :base, :dates_required
    end

    def validate_only_one_active_sprint
      return if Sprint.for_project(model.project).active.where.not(id: model.id).none?

      errors.add :status, :only_one_active_sprint_allowed
    end

    # A project's own sprints shouldn't be started if the project is set to receive sprints.
    # Ignoring the multiple active sprints settings, because that is available only when
    # the project is not sharing sprints.
    def validate_not_receiving_shared_sprints
      return unless model.project.receive_shared_sprints?

      errors.add :status, :cannot_start_while_receiving_shared_sprints
    end
  end
end
