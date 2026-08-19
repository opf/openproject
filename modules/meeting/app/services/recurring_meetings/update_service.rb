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
  class UpdateService < ::BaseServices::Update
    include WithTemplate

    protected

    def validate_params
      @old_schedule_model = model.dup
      @old_location = model.template.location
      @old_title = model.title
      super
    end

    def after_perform(call)
      return call unless call.success?

      recurring_meeting = call.result

      if should_reschedule?(recurring_meeting)
        reschedule_future_occurrences(recurring_meeting)
        reschedule_init_job(recurring_meeting)
        send_updated_mail(recurring_meeting)
      end

      cleanup_cancelled_schedules(recurring_meeting)
      update_future_occurrence_titles(recurring_meeting)

      update_template(call)
    end

    def update_template(call)
      recurring_meeting = call.result
      template = recurring_meeting.template

      unless template.update(@template_params)
        call.merge! ServiceResult.failure(result: template, errors: template.errors)
      end

      call
    end

    def reschedule_future_occurrences(recurring_meeting)
      if only_time_of_day_changed?(recurring_meeting) && !multi_instances_per_day?(recurring_meeting)
        update_time_of_day(recurring_meeting)
      else
        remove_cancelled_schedules(recurring_meeting)
        reschedule_all_occurrences(recurring_meeting)
      end
    end

    def only_time_of_day_changed?(recurring_meeting)
      changes = recurring_meeting.previous_changes.keys
      changes.include?("start_time_hour") && changes.exclude?("start_date")
    end

    ##
    # In some edit cases, we end up with multiple meetings being created
    # per day. This ensures we can reschedule them on update.
    def multi_instances_per_day?(recurring_meeting)
      recurring_meeting
        .meetings
        .not_templated
        .where.not(recurrence_start_time: nil)
        .group("recurrence_start_time::date")
        .having("COUNT(*) > 1")
        .exists?
    end

    def update_time_of_day(recurring_meeting) # rubocop:disable Metrics/AbcSize
      recurring_meeting
        .meetings
        .not_templated
        .where.not(recurrence_start_time: nil)
        .find_each do |meeting|
        # Ensure we treat the recurrence_start_time as a local time of the series
        occurrence_time = meeting.recurrence_start_time.in_time_zone(recurring_meeting.time_zone)
        # change only the hour/minute component
        new_time = occurrence_time.change(
          hour: recurring_meeting.start_time.hour,
          min: recurring_meeting.start_time.min
        )

        Meeting.transaction do
          meeting.update_column(:recurrence_start_time, new_time)
          meeting.update_column(:start_time, new_time) if meeting.start_time.future?
        end
      end
    end

    def remove_cancelled_schedules(recurring_meeting)
      recurring_meeting
        .meetings
        .not_templated
        .cancelled
        .destroy_all
    end

    def reschedule_all_occurrences(recurring_meeting)
      future_meetings = future_occurrences_to_reschedule(recurring_meeting)
      next_occurrences = recurring_meeting.scheduled_occurrences(limit: future_meetings.count)
      pairs = ordered_reschedule_pairs(future_meetings, next_occurrences)

      Meeting.transaction do
        pairs.each do |meeting, next_time|
          next unless next_time

          meeting.update_column(:recurrence_start_time, next_time)
          meeting.update_column(:start_time, next_time)
        end
      end
    end

    def future_occurrences_to_reschedule(recurring_meeting)
      recurring_meeting
        .meetings
        .not_templated
        .not_cancelled
        .where.not(recurrence_start_time: nil)
        .where(recurrence_start_time: Time.current..)
        .order(recurrence_start_time: :asc)
        .to_a
    end

    # Pair each existing meeting with its new scheduled time.
    # Update order is important here: PostgreSQL enforces the unique constraint on recurrence_start_time
    # after every individual write, not just at the end of the transaction.
    # If we do not order them here, we would violate the unique constraint.
    def ordered_reschedule_pairs(future_meetings, next_occurrences)
      pairs = future_meetings.zip(next_occurrences.map(&:to_time))
      last_old = future_meetings.last&.recurrence_start_time
      last_new = next_occurrences.last&.to_time

      # When the schedule expands (the last new slot is later than the last old slot), we process
      # from last to first so each meeting moves into a slot already vacated by the one after it.
      # When the schedule ends up tighter, first-to-last is still safe since each newly freed slot is earlier than the next.
      pairs.reverse! if last_new && last_old && last_new > last_old

      pairs
    end

    def cleanup_cancelled_schedules(recurring_meeting)
      recurring_meeting
        .meetings
        .not_templated
        .cancelled
        .find_each do |meeting|
          occurring = recurring_meeting.schedule.occurs_at?(meeting.recurrence_start_time)
          meeting.destroy! unless occurring
        end
    end

    def update_future_occurrence_titles(recurring_meeting)
      new_title = @template_params[:title]
      return if new_title == @old_title

      recurring_meeting
        .meetings
        .not_templated
        .not_cancelled
        .where.not(recurrence_start_time: nil)
        .where(recurrence_start_time: Time.current..)
        .update_all(title: new_title)
    end

    def send_updated_mail(recurring_meeting)
      return unless recurring_meeting.notify?

      recurring_meeting
        .template
        .participants
        .invited
        .find_each do |participant|
          # Generate old schedule in each participant's locale
          old_schedule = User.execute_as(participant.user) do
            @old_schedule_model.full_schedule_in_words
          end

          MeetingSeriesMailer.updated(
            recurring_meeting,
            participant.user,
            User.current,
            changes: { old_schedule:, old_location: @old_location }
          ).deliver_now
      end
    end

    def reschedule_init_job(recurring_meeting)
      concurrency_key = InitNextOccurrenceJob.unique_key(recurring_meeting)

      # Delete all scheduled jobs for this meeting
      GoodJob::Job.where(finished_at: nil, concurrency_key:).delete_all

      # Don't init the next meeting in draft mode
      return if recurring_meeting.template.draft?

      # Ensure we init the next meeting directly
      InitNextOccurrenceJob.perform_now(recurring_meeting, recurring_meeting.next_occurrence)
    end

    def should_reschedule?(recurring_meeting)
      return false if recurring_meeting.next_occurrence.nil?

      recurring_meeting.reschedule_required?(previous: true)
    end
  end
end
