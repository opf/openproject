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
  # Compute the diff between two meeting journals and sends
  # the appropriate set of emails.
  #
  # For series templates (meeting.template? == true), series schedule updates are
  # handled by RecurringMeetings::UpdateService directly (it has the full context only then).
  # This service therefore only dispatches participant-change emails for series templates and one-time meetings
  class DispatchAggregatedNotificationsService
    attr_reader :meeting, :since_journal, :latest_journal, :actor, :added_user_ids,
                :removed_user_ids, :still_invited_ids, :users_by_id, :added_names,
                :removed_names, :attribute_changes

    def initialize(meeting:, since_journal:, latest_journal:, since_invited_ids: nil, since_attributes: nil)
      @meeting = meeting
      @since_journal = since_journal
      @latest_journal = latest_journal
      @since_invited_ids_override = since_invited_ids
      @since_attributes_override = normalize_since_attributes(since_attributes)
    end

    def call
      return unless Journal::NotificationConfiguration.active? && meeting.send_emails?

      prepare_changes

      send_direct_notifications
      send_update_notifications if update_notifications?
    end

    private

    def prepare_changes # rubocop:disable Metrics/AbcSize
      @actor = latest_journal.user

      prepare_participant_changes
      @users_by_id = User.where(id: changed_user_ids).index_by(&:id)

      @added_names = added_user_ids.filter_map { users_by_id[it]&.name }
      @removed_names = removed_user_ids.filter_map { users_by_id[it]&.name }
      @attribute_changes = meeting.template? ? {} : compute_attribute_changes
    end

    def prepare_participant_changes
      since_invited_ids = @since_invited_ids_override || invited_user_ids_from(since_journal)
      latest_invited_ids = invited_user_ids_from(latest_journal)

      @added_user_ids = latest_invited_ids - since_invited_ids
      @removed_user_ids = since_invited_ids - latest_invited_ids
      @still_invited_ids = latest_invited_ids & since_invited_ids
    end

    def changed_user_ids
      (added_user_ids + removed_user_ids + still_invited_ids).uniq
    end

    def send_direct_notifications
      added_user_ids.each { |uid| send_invite(users_by_id[uid], actor) }
      removed_user_ids.each { |uid| send_cancellation(users_by_id[uid], actor) }
    end

    def send_update_notifications
      still_invited_ids.filter_map { |uid| users_by_id[uid] }.each do |recipient|
        send_updated(recipient, actor, attribute_changes, added_names:, removed_names:)
      end
    end

    def update_notifications?
      attribute_changes.any? || added_names.any? || removed_names.any?
    end

    def invited_user_ids_from(journal)
      return [] unless journal

      journal.participant_journals.where(invited: true).pluck(:user_id)
    end

    def compute_attribute_changes
      latest_data = latest_journal.data
      return {} unless latest_data

      since_attributes = @since_attributes_override || attributes_from_journal(since_journal)
      return {} unless since_attributes

      changes = {}
      %i[title location start_time duration].each do |attr|
        next unless since_attributes.key?(attr.to_s) && latest_data.respond_to?(attr)

        old_val = since_attributes[attr.to_s]
        new_val = latest_data.send(attr)
        changes[attr] = [old_val, new_val] if old_val != new_val
      end
      changes
    end

    def attributes_from_journal(journal)
      data = journal&.data
      return unless data

      %w[title location start_time duration].index_with { |attr| data.public_send(attr) }
    end

    def normalize_since_attributes(attributes)
      attributes = attributes&.stringify_keys
      return unless attributes

      attributes["start_time"] = Time.zone.parse(attributes["start_time"]) if attributes["start_time"].is_a?(String)
      attributes
    end

    def send_invite(recipient, actor)
      return unless recipient

      if meeting.template?
        MeetingSeriesMailer.invited(meeting.recurring_meeting, recipient, actor).deliver_later
      else
        MeetingMailer.invited(meeting, recipient, actor).deliver_later
      end
    end

    def send_cancellation(recipient, actor)
      return unless recipient

      if meeting.template?
        MeetingMailer.cancelled_series(meeting.recurring_meeting, recipient, actor).deliver_later
      else
        MeetingMailer.cancelled(meeting, recipient, actor).deliver_later
      end
    end

    def send_updated(recipient, actor, attribute_changes, added_names: [], removed_names: [])
      if meeting.template?
        send_series_updated(recipient, actor, added_names:, removed_names:)
      else
        send_meeting_updated(recipient, actor, attribute_changes, added_names:, removed_names:)
      end
    end

    def send_series_updated(recipient, actor, added_names:, removed_names:)
      series = meeting.recurring_meeting
      MeetingSeriesMailer.updated(series, recipient, actor,
                                  changes: { old_schedule: series.full_schedule_in_words,
                                             old_location: series.location },
                                  added_participants: added_names,
                                  removed_participants: removed_names).deliver_later
    end

    def send_meeting_updated(recipient, actor, attribute_changes, added_names:, removed_names:)
      MeetingMailer.updated(meeting, recipient, actor,
                            changes: meeting_changes(attribute_changes),
                            added_participants: added_names,
                            removed_participants: removed_names).deliver_later
    end

    def meeting_changes(attribute_changes) # rubocop:disable Metrics/AbcSize
      title      = attribute_changes[:title]      || [meeting.title,      meeting.title]
      start_time = attribute_changes[:start_time] || [meeting.start_time, meeting.start_time]
      duration   = attribute_changes[:duration]   || [meeting.duration,   meeting.duration]
      location   = attribute_changes[:location]   || [meeting.location,   meeting.location]

      { old_title: title[0], new_title: title[1],
        old_start: start_time[0], new_start: start_time[1],
        old_duration: duration[0], new_duration: duration[1],
        old_location: location[0], new_location: location[1] }
    end
  end
end
