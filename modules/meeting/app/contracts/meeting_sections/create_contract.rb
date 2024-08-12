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

module MeetingSections
  class CreateContract < BaseContract
    # Note:
    # the CreateContract is currently only called internally in the create action which substitutes the new action
    # of the controller. The contract is not used in the context of a form.
    # Only the UpdateContract is used alongside a user facing form.
    # Thus we're not validating for title presence here, which enables us to create a section without a title which is required for
    # the current UX implementation

    validate :user_allowed_to_add,
             :validate_meeting_existence

    def self.assignable_meetings(user)
      StructuredMeeting
        .open
        .visible(user)
    end

    ##
    # Meeting agenda items can currently be only created
    # through the project permission :manage_agendas
    # When MeetingRole becomes available, agenda items will
    # be created through meeting permissions :manage_agendas
    def user_allowed_to_add
      # when creating a meeting agenda item from the work package tab and not selecting a meeting
      # the meeting and therefore the project is not set
      # in this case we only want to show the "Meeting can't be blank" error instead of a misleading permission base error
      # the error is added by the models presence validation
      return unless visible?

      unless user.allowed_in_project?(:manage_agendas, model.project)
        errors.add :base, :error_unauthorized
      end
    end

    ##
    # A stale browser window might provide an already deleted meeting as an option when creating an agenda item from the
    # work package tab. This would lead to an 500 server error when trying to save the agenda item.
    def validate_meeting_existence
      # when creating a meeting agenda item from the work package tab and not selecting a meeting
      # the meeting and therefore the project is not set
      # in this case we only want to show the "Meeting can't be blank" error instead of a misleading not existance error
      # the error is added by the models presence validation
      return if model.meeting.nil?

      errors.add :base, :does_not_exist unless visible?
    end

    private

    def visible?
      @visible ||= model.meeting&.visible?(user)
    end
  end
end
