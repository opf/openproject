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

module MeetingAgendaItems
  class MoveToNextMeetingContract < ::ModelContract
    validate :validate_recurring_series
    validate :validate_not_template, if: -> { errors.empty? }
    validate :validate_not_closed, if: -> { errors.empty? }
    validate :validate_manage_permission, if: -> { errors.empty? }

    protected

    def validate_model?
      false
    end

    private

    def meeting
      model.meeting
    end

    def validate_recurring_series
      errors.add :base, :not_in_recurring_series unless meeting.recurring?
    end

    def validate_not_template
      errors.add :base, :meeting_is_template if meeting.templated?
    end

    def validate_not_closed
      errors.add :base, :meeting_closed if meeting.closed?
    end

    def validate_manage_permission
      errors.add :base, :error_unauthorized unless user.allowed_in_project?(:manage_agendas, meeting.project)
    end
  end
end
