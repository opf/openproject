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

module TimeEntries
  class DaysAndHoursForm < ApplicationForm
    delegate :project, to: :model

    form do |f|
      # force the form to submit the ongoing flag as false to stop active timers
      f.hidden name: :ongoing, value: false

      f.single_date_picker name: :spent_on,
                           type: "date",
                           required: true,
                           datepicker_options: { inDialog: "time-entry-dialog" },
                           value: model.spent_on&.iso8601,
                           label: TimeEntry.human_attribute_name(:spent_on)

      if show_start_and_end_time_fields?
        f.group(layout: :horizontal) do |g|
          g.text_field name: :start_time,
                       type: "time",
                       required: start_and_end_time_required?,
                       label: TimeEntry.human_attribute_name(:start_time),
                       value: start_time_in_local_time,
                       show_clear_button: true,
                       data: {
                         "time-entry-target" => "startTimeInput",
                         "action" => "input->time-entry#timeInputChanged"
                       }

          g.text_field name: :end_time,
                       type: "time",
                       required: start_and_end_time_required?,
                       label: TimeEntry.human_attribute_name(:end_time),
                       value: end_time_in_local_time,
                       show_clear_button: true,
                       caption: end_time_caption,
                       data: {
                         "time-entry-target" => "endTimeInput",
                         "action" => "input->time-entry#timeInputChanged"
                       }
        end
      end

      f.hidden name: :hours,
               value: precise_hours_value,
               data: { "time-entry-target" => "hoursHiddenInput" }

      f.text_field name: :hours_display,
                   required: true,
                   label: TimeEntry.human_attribute_name(:hours),
                   value: hours_value,
                   data: { "time-entry-target" => "hoursInput",
                           "action" => "blur->time-entry#hoursChanged keypress.enter->time-entry#hoursKeyEnterPress" }
    end

    private

    def start_time_in_local_time
      return if model.start_timestamp.blank?

      model.start_timestamp.in_time_zone(model.user.time_zone).strftime("%H:%M")
    end

    def end_time_in_local_time
      return if model.end_timestamp.blank?

      model.end_timestamp.in_time_zone(model.user.time_zone).strftime("%H:%M")
    end

    def show_start_and_end_time_fields?
      TimeEntry.can_track_start_and_end_time?
    end

    def start_and_end_time_required?
      TimeEntry.must_track_start_and_end_time?
    end

    def hours_value
      if model.ongoing?
        ChronicDuration.output(model.ongoing_hours * 3600, format: :hours_only)
      elsif model.hours.present?
        ChronicDuration.output(model.hours * 3600, format: :hours_only)
      else
        ""
      end
    end

    def precise_hours_value
      model.ongoing? ? model.ongoing_hours : model.hours
    end

    def end_time_caption # rubocop:disable Metrics/AbcSize
      relevant_hours = model.ongoing? ? model.ongoing_hours : model.hours

      return if model.start_time.blank?
      return if relevant_hours.blank?

      end_time_in_minutes = model.start_time + (relevant_hours * 60)

      return if end_time_in_minutes <= (24 * 60)

      diff_in_days = (end_time_in_minutes / (60 * 24)).floor

      "+#{I18n.t('datetime.distance_in_words.x_days', count: diff_in_days)}"
    end
  end
end
