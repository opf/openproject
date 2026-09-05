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

module API
  module V3
    module RecurringMeetings
      class RecurringMeetingsAPI < ::API::OpenProjectAPI
        helpers do
          def represent_recurring_meeting_result(call)
            if call.success?
              status 200
              ::API::V3::RecurringMeetings::RecurringMeetingRepresenter.create(
                @recurring_meeting.reload, current_user:, embed_links: true
              )
            elsif call.errors.blank?
              raise ::API::Errors::UnprocessableContent.new(call.message)
            else
              fail ::API::Errors::ErrorBase.create_and_merge_errors(call.errors)
            end
          end
        end

        resources :recurring_meetings do
          get &::API::V3::Utilities::Endpoints::Index.new(model: RecurringMeeting).mount

          post(&::API::V3::Utilities::Endpoints::Create
                 .new(model: RecurringMeeting)
                 .mount)

          route_param :id, type: Integer, desc: "Recurring meeting ID" do
            after_validation do
              @recurring_meeting = RecurringMeeting.visible.find(declared_params[:id])
            end

            get &::API::V3::Utilities::Endpoints::Show.new(model: RecurringMeeting).mount

            patch &::API::V3::Utilities::Endpoints::Update.new(model: RecurringMeeting).mount

            delete &::API::V3::Utilities::Endpoints::Delete.new(model: RecurringMeeting).mount

            post "end" do
              authorize_in_project(:edit_meetings, project: @recurring_meeting.project)

              call = ::RecurringMeetings::EndService
                       .new(@recurring_meeting, current_user:)
                       .call

              represent_recurring_meeting_result(call)
            end

            params do
              requires :notify,
                       type: Boolean,
                       desc: "Enable email notifications for the series"
            end
            post "template_completed" do
              authorize_in_project(:edit_meetings, project: @recurring_meeting.project)

              call = ::RecurringMeetings::TemplateCompletedService
                       .new(user: current_user, recurring_meeting: @recurring_meeting)
                       .call(notify: params[:notify])

              represent_recurring_meeting_result(call)
            end

            mount ::API::V3::RecurringMeetings::OccurrencesByRecurringMeetingAPI
          end
        end
      end
    end
  end
end
