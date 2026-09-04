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
      @previous_snapshot = ScheduleSnapshot.capture(model)
      @old_location = model.template.location
      @old_title = model.title
      super
    end

    def after_perform(call)
      return call unless call.success?

      recurring_meeting = call.result
      recurring_meeting.bump_ical_sequence!

      # Make sure we update the template before sending out any emails
      # to make sure it's attributes (such as a location change) are correctly used
      update_template(call)

      return call unless call.success?

      started_new_schedule = start_new_schedule(recurring_meeting)

      if should_reschedule?(recurring_meeting)
        reschedule_future_occurrences(recurring_meeting)
        reschedule_init_job(recurring_meeting)
      end

      if send_updated_mail?(recurring_meeting)
        send_updated_mail(recurring_meeting, historic_schedule: started_new_schedule)
      end

      cleanup_cancelled_schedules(recurring_meeting)
      update_future_occurrence_titles(recurring_meeting)

      call
    end

    # Not should_reschedule?, which is false when the series has no next occurrence. An update
    # that shortened a series into the past must still tell the participants.
    # RecurringMeetings::EndService is the exception. It sends its own ended_series mail after
    # this call, thus a mail from here would arrive twice.
    def send_updated_mail?(recurring_meeting)
      recurring_meeting.reschedule_required?(previous: true) &&
        contract_class != RecurringMeetings::EndSeriesContract
    end

    # Updating this series will replace and rewrite occurrences. IF we need to start
    # a new schedule, we have to do it before this update.
    def start_new_schedule(recurring_meeting)
      return unless recurring_meeting.schedule_changed?(previous: true)

      StartNewScheduleService
        .new(recurring_meeting:, previous: @previous_snapshot)
        .call
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

    def send_updated_mail(recurring_meeting, historic_schedule: false)
      return unless recurring_meeting.notify?

      recurring_meeting
        .template
        .participants
        .invited
        .find_each do |participant|
        send_historic_schedule_mail(recurring_meeting, participant) if historic_schedule

        MeetingSeriesMailer.updated(
          recurring_meeting,
          participant.user,
          User.current,
          changes: updated_mail_changes(recurring_meeting, participant.user)
        ).deliver_now
      end
    end

    # RFC 5546 3.2.2 permits one UID per REQUEST, thus the schedule that ended needs its own
    # message. It goes first, so the client sees the end before the new series starts.
    def send_historic_schedule_mail(recurring_meeting, participant)
      historic = recurring_meeting.last_historic_schedule
      # A person who joined after the change never had the old series. A REQUEST for it would
      # add a block of meetings that they never attended.
      return if participant.created_at > historic.created_at

      MeetingSeriesMailer.updated(
        recurring_meeting,
        participant.user,
        User.current,
        changes: historic_schedule_changes(historic, participant.user),
        historic_schedule: true
      ).deliver_now
    end

    # The mail for the schedule that ended shows the same wording as any other update. Its "new"
    # side is the old schedule with an end date, thus the reader sees what changed for it.
    def historic_schedule_changes(historic, recipient)
      ended = ended_schedule_model(historic)

      User.execute_as(recipient) do
        {
          old_location: @old_location,
          new_location: @old_location,
          old_schedule: @old_schedule_model.full_schedule_in_words,
          new_schedule: ended.full_schedule_in_words
        }
      end
    end

    # A fresh record, not a dup of @old_schedule_model, which memoizes its schedule as soon as
    # anything asks it for words.
    def ended_schedule_model(historic)
      RecurringMeeting
        .new(@old_schedule_model.attributes.slice(*schedule_columns))
        .tap do |ended|
          ended.end_after = :specific_date
          ended.end_date = historic.ends_at.in_time_zone(historic.time_zone).to_date
        end
    end

    # start_date and start_time_hour are virtual and read from instance variables, thus
    # #attributes reports them as nil. That nil makes the new record derive its start time from
    # the two of them, and the start time is then lost.
    def schedule_columns
      RecurringMeeting::SCHEDULE_ATTRIBUTES & RecurringMeeting.column_names
    end

    # Only include old_schedule when the recurrence actually changed.
    # Previously, we compared the localized schedule which would always differ.
    def updated_mail_changes(recurring_meeting, recipient)
      changes = { old_location: @old_location }
      return changes unless recurring_meeting.schedule_changed?(previous: true)

      changes.merge(
        old_schedule: User.execute_as(recipient) { @old_schedule_model.full_schedule_in_words }
      )
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
