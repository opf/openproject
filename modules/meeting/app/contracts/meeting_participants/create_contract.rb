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
module MeetingParticipants
  class CreateContract < ::ModelContract
    attribute :meeting
    attribute :user_id
    attribute :invited
    attribute :attended

    validate :user_can_see_meetings_in_project
    validate :user_allowed_to_edit

    private

    def user_allowed_to_edit
      return if model.meeting.nil?

      unless user.allowed_in_project?(:edit_meetings, model.meeting.project)
        errors.add(:base, :error_unauthorized)
      end
    end

    def user_can_see_meetings_in_project
      return if model.user.nil? || model.meeting.nil?

      unless model.user.allowed_in_project?(:view_meetings, model.meeting.project)
        errors.add(:user, :user_invalid)
      end
    end
  end
end
