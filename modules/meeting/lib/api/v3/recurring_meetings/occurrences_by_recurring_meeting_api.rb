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
      class OccurrencesByRecurringMeetingAPI < ::API::OpenProjectAPI
        helpers do
          def build_occurrence(start_time:, meeting: nil)
            Occurrence.new(
              start_time:,
              recurring_meeting_id: @recurring_meeting.id,
              meeting_id: meeting&.id,
              meeting_state: meeting&.state
            )
          end

          def occurrences_from_meetings(meetings)
            meetings.map { |m| build_occurrence(start_time: m.recurrence_start_time, meeting: m) }
          end

          def occurrence_collection(occurrences, self_link:)
            OccurrenceCollectionRepresenter.new(occurrences, self_link:, current_user:)
          end

          def persisted_upcoming
            @recurring_meeting.meetings
              .recurring_occurrence
              .upcoming
              .index_by(&:recurrence_start_time)
          end

          def opened_start_times(persisted)
            persisted
              .reject { |_, m| m.cancelled? }
              .keys
              .to_set
          end

          def computed_start_times(opened_times, limit)
            from_time = Time.current - (@recurring_meeting.template&.duration || 1).hours
            @recurring_meeting
              .scheduled_occurrences(limit: limit + opened_times.size, from_time:)
              .reject { |t| opened_times.include?(t) }
              .first(limit)
          end

          def build_upcoming_occurrences(limit: 20)
            persisted = persisted_upcoming
            opened_times = opened_start_times(persisted)
            all_times = (opened_times.to_a + computed_start_times(opened_times, limit)).sort
            all_times.map { |t| build_occurrence(start_time: t, meeting: persisted[t]) }
          end
        end

        namespace :occurrences do
          namespace :upcoming do
            params do
              optional :limit, type: Integer, default: 20, desc: "Number of occurrences to return"
            end

            get do
              occurrence_collection(
                build_upcoming_occurrences(limit: declared_params[:limit]),
                self_link: api_v3_paths.recurring_meeting_occurrences_upcoming(@recurring_meeting.id)
              )
            end
          end

          namespace :past do
            get do
              occurrence_collection(
                occurrences_from_meetings(@recurring_meeting.scheduled_instances(upcoming: false)),
                self_link: api_v3_paths.recurring_meeting_occurrences_past(@recurring_meeting.id)
              )
            end
          end

          namespace :cancelled do
            get do
              occurrence_collection(
                occurrences_from_meetings(@recurring_meeting.meetings.recurring_occurrence.cancelled),
                self_link: api_v3_paths.recurring_meeting_occurrences_cancelled(@recurring_meeting.id)
              )
            end
          end

          namespace :open do
            get do
              occurrence_collection(
                occurrences_from_meetings(@recurring_meeting.meetings.recurring_occurrence.not_cancelled),
                self_link: api_v3_paths.recurring_meeting_occurrences_open(@recurring_meeting.id)
              )
            end
          end

          route_param :start_time, type: DateTime, desc: "Occurrence start time (ISO 8601)" do
            namespace :init do
              post do
                authorize_in_project(:create_meetings, project: @recurring_meeting.project)
                start_time = declared_params[:start_time]
                call = ::RecurringMeetings::InitOccurrenceService
                         .new(user: current_user, recurring_meeting: @recurring_meeting)
                         .call(start_time:)

                if call.success?
                  status 201
                  ::API::V3::Meetings::MeetingRepresenter.create(call.result, current_user:, embed_links: true)
                else
                  fail ::API::Errors::ErrorBase.create_and_merge_errors(call.errors)
                end
              end
            end

            delete do
              start_time = declared_params[:start_time]
              authorize_in_project(:edit_meetings, project: @recurring_meeting.project)

              existing = @recurring_meeting.meetings.not_templated.find_by(recurrence_start_time: start_time)

              if existing.present? && !existing.cancelled?
                fail ::API::Errors::Conflict.new(
                  message: "Cannot cancel an already instantiated occurrence. Delete the meeting instead."
                )
              end

              unless existing
                template = @recurring_meeting.template
                @recurring_meeting.meetings.create!(
                  project: @recurring_meeting.project,
                  author: current_user,
                  start_time:,
                  recurrence_start_time: start_time,
                  state: :cancelled,
                  template: false,
                  title: template.title,
                  duration: template.duration
                )
              end

              status 204
            end
          end
        end
      end
    end
  end
end
