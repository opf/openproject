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

module Meetings
  module DemoData
    # Instantiates the next few occurrences of the weekly meeting series (each inherits the
    # template's participants) and adds a bit of realism to the responses: most attendees accept,
    # but on some occurrences a few decline or are tentative and one-off guests are invited.
    # Runs *after* the finalizer, which opens the template and creates the first occurrence.
    class MeetingOccurrencesSeeder < ::Seeder
      # How many occurrences of the series should exist after seeding.
      OCCURRENCE_COUNT = 5

      attr_reader :project

      def initialize(project, seed_data)
        super(seed_data)
        @project = project
      end

      def applicable?
        series&.template.present?
      end

      def not_applicable_message
        "Skipping meeting occurrences as no meeting series exists for project #{project.identifier}"
      end

      def seed_data!
        print_status "    ↳ Instantiating meeting occurrences" do
          instantiate_occurrences
          vary_responses(series.meetings.not_templated.order(:start_time).to_a)
        end
      end

      private

      def series
        @series ||= project.recurring_meetings.first
      end

      # Instantiates the next scheduled occurrences that have not been materialized yet, using the
      # same service the application uses. The occurrences already created by the finalizer (and
      # its recurrence job) are skipped.
      def instantiate_occurrences
        series.scheduled_occurrences(limit: OCCURRENCE_COUNT).each do |start_time|
          next if series.meetings.not_templated.exists?(recurrence_start_time: start_time)

          ::RecurringMeetings::InitOccurrenceService
            .new(user: admin_user, recurring_meeting: series)
            .call(start_time:)
            .on_failure { |result| raise "Failed to instantiate meeting occurrence: #{result.message}" }
        end
      end

      def vary_responses(occurrences)
        # The first occurrence keeps everybody accepted. On later occurrences some people can't
        # make it, and a couple of one-off guests are invited.
        if (second = occurrences[1])
          set_response(second, :user__fritz_finance, :declined)
          set_response(second, :user__evan_events, :tentative)
          invite_individual(second, :user__olga_ops)
          invite_individual(second, :user__tessa_tester)
        end

        if (third = occurrences[2])
          set_response(third, :user__marko_marketing, :tentative)
          invite_individual(third, :user__adam_admin)
        end
      end

      def set_response(meeting, reference, status)
        user = seed_data.find_reference(reference, default: nil)
        return unless user

        meeting.participants.find_by(user:)&.update!(participation_status: status)
      end

      def invite_individual(meeting, reference)
        user = seed_data.find_reference(reference, default: nil)
        return unless user

        participant = meeting.participants.find_or_initialize_by(user:)
        participant.update!(invited: true, participation_status: :accepted)
      end
    end
  end
end
