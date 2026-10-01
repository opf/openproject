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
    # Finalizes seeded meeting series after the agenda items have been seeded:
    # transitions the template out of draft and instantiates the first
    # occurrence via the same service the UI uses, so any future side effects
    # of completing a template are picked up automatically.
    class MeetingSeriesFinalizerSeeder < ::Seeder
      attr_reader :project

      def initialize(project, seed_data)
        super(seed_data)
        @project = project
      end

      def applicable?
        draft_series.any?
      end

      def not_applicable_message
        "Skipping meeting series finalization as no draft templates exist for project #{project.identifier}"
      end

      def seed_data!
        draft_series.each { |series| finalize_series(series) }
      end

      private

      def draft_series
        project
          .recurring_meetings
          .joins(:template)
          .where(meetings: { state: Meeting.states[:draft] })
      end

      def finalize_series(series)
        first_occurrence = series.first_occurrence&.to_time
        return if first_occurrence.nil?

        call = ::RecurringMeetings::TemplateCompletedService
                 .new(user: series.template.author, recurring_meeting: series)
                 .call(notify: false, first_occurrence:)

        if call.success?
          schedule_next_occurrence_job(series, first_occurrence)
        else
          raise "Failed to finalize meeting series ##{series.id}: #{call.message}"
        end
      end

      def schedule_next_occurrence_job(series, from_time)
        next_occurrence = series.next_occurrence(from_time:)
        return if next_occurrence.nil?

        ::RecurringMeetings::InitNextOccurrenceJob
          .set(wait_until: from_time)
          .perform_later(series, next_occurrence)
      end
    end
  end
end
