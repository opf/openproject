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

module RecurringMeetings
  class InitNextOccurrenceJob < ApplicationJob
    include GoodJob::ActiveJobExtensions::Concurrency
    discard_on ActiveJob::DeserializationError

    CONCURRENCY_KEY_BASE = "RecurringMeetings::InitNextOccurrenceJob-".freeze

    good_job_control_concurrency_with(
      # Allow the running job to enqueue the next one
      total_limit: 2,
      # But allow only one enqueued job
      enqueue_limit: 1,
      # And one running job
      perform_limit: 1,
      key: -> { self.class.unique_key(arguments.first) }
    )

    def self.delete_jobs(recurring_meeting)
      concurrency_key = unique_key(recurring_meeting)
      GoodJob::Job.where(concurrency_key:).delete_all
    end

    def self.unique_key(recurring_meeting)
      "#{CONCURRENCY_KEY_BASE}#{recurring_meeting.id}"
    end

    attr_accessor :recurring_meeting, :scheduled_time

    def perform(recurring_meeting, scheduled_time)
      self.recurring_meeting = recurring_meeting
      return if recurring_meeting.template.draft?

      self.scheduled_time = scheduled_time.in_time_zone(recurring_meeting.time_zone)

      # Schedule the next job
      schedule_next_job

      # Schedule the given occurrence, if not instantiated
      check_occurrence
    rescue StandardError => e
      Rails.logger.error { "Error while initializing next occurrence for series ##{recurring_meeting.id}: #{e.message}" }
    end

    private

    def check_occurrence # rubocop:disable Metrics/AbcSize
      if occurrence_instantiated?
        Rails.logger.debug { "Will not create next occurrence for series ##{recurring_meeting.id} as already instantiated" }
        return
      end

      if occurrence_cancelled?
        Rails.logger.debug { "Will not create next occurrence for series ##{recurring_meeting.id} as already cancelled" }
        return
      end

      unless occurring_at_scheduled_time?
        Rails.logger.debug { "The given schedule #{scheduled_time} (no longer) exists for series ##{recurring_meeting.id}" }
        return
      end

      init_meeting
    end

    def init_meeting
      call = ::RecurringMeetings::InitOccurrenceService
        .new(user: User.system, recurring_meeting:)
        .call(start_time: scheduled_time)

      call.on_success do
        Rails.logger.debug { "Initialized occurrence for series ##{recurring_meeting} at #{scheduled_time}" }
      end

      call.on_failure do
        Rails.logger.error do
          "Could not create next occurrence for series ##{recurring_meeting}: #{call.message}"
        end
      end
    end

    ##
    # Schedule when this job should be run the next time
    # When the next meeting takes place
    def schedule_next_job
      if next_scheduled_time.nil?
        Rails.logger.info { "Meeting series ##{recurring_meeting.id} is ending." }
        return
      end

      self
        .class
        .set(wait_until: scheduled_time)
        .perform_later(recurring_meeting, next_scheduled_time)
    end

    ##
    # Return whether the given scheduled_time is occurring
    # This might no longer be the case if the meeting was rescheduled.
    def occurring_at_scheduled_time?
      recurring_meeting.schedule.occurs_at?(scheduled_time)
    end

    ##
    # Return if there is already an instantiated (non-cancelled) meeting
    # for the current scheduled_time
    def occurrence_instantiated?
      recurring_meeting
        .meetings
        .not_templated
        .not_cancelled
        .exists?(recurrence_start_time: scheduled_time)
    end

    ##
    # Return if the current scheduled time is cancelled
    def occurrence_cancelled?
      recurring_meeting
        .meetings
        .not_templated
        .cancelled
        .exists?(recurrence_start_time: scheduled_time)
    end

    def next_scheduled_time
      return @next_scheduled_time if defined?(@next_scheduled_time)

      @next_scheduled_time = recurring_meeting
        .next_occurrence(from_time: scheduled_time)
        &.to_time
    end
  end
end
