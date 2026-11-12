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

module RecurringMeetings
  class CreateService < ::BaseServices::Create
    include WithTemplate

    protected

    def after_perform(call)
      return call unless call.success?

      recurring_meeting = call.result
      if call.success?
        create_template_call = create_meeting_template(recurring_meeting)

        # make sure that the template is correctly loaded in the association
        call.result.reload_template if create_template_call.success?

        call.merge! create_template_call
      end

      call
    end

    def create_meeting_template(recurring_meeting)
      params = @template_params.merge(
        template: true,
        recurring_meeting:,
        project: recurring_meeting.project
      )

      Meetings::CreateService
        .new(user: user)
        .call(params)
    end
  end
end
