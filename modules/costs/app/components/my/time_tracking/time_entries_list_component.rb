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

module My
  module TimeTracking
    class TimeEntriesListComponent < OpPrimer::BorderBoxTableComponent
      include OpTurbo::Streamable
      columns :spent_on, :time, :hours, :subject, :project, :activity, :comments
      main_column :time, :subject, :project

      def row_class
        TimeEntryRow
      end

      def mobile_title
        TimeEntry.model_name.human(count: 2)
      end

      def has_actions?
        true
      end

      def action_row_header_content
        return unless can_create_time_entry?
        return if options[:mode] == :month

        render(Primer::Beta::IconButton.new(
                 icon: "plus",
                 scheme: :invisible,
                 size: :small,
                 tag: :a,
                 tooltip_direction: :e,
                 href: "#",
                 data: {
                   action: "my--time-tracking#newTimeEntry",
                   "my--time-tracking-date-param" => options[:date]
                 },
                 label: t(:button_add_time_entry),
                 aria: { label: t(:button_add_time_entry) }
               ))
      end

      def headers
        [
          options[:mode] == :month ? [:spent_on, { caption: TimeEntry.human_attribute_name(:spent_on) }] : nil,
          TimeEntry.can_track_start_and_end_time? ? [:time, { caption: TimeEntry.human_attribute_name(:time) }] : nil,
          [:hours, { caption: TimeEntry.human_attribute_name(:hours) }],
          [:subject, { caption: TimeEntry.human_attribute_name(:subject) }],
          [:project, { caption: TimeEntry.human_attribute_name(:project) }],
          [:activity, { caption: TimeEntry.human_attribute_name(:activity) }],
          [:comments, { caption: TimeEntry.human_attribute_name(:comments) }]
        ].compact
      end

      def skip_column?(column)
        if column == :time
          !TimeEntry.can_track_start_and_end_time?
        elsif column == :spent_on
          options[:mode] != :month
        else
          false
        end
      end

      def can_create_time_entry?
        User.current.allowed_in_any_work_package?(:log_own_time) || User.current.allowed_in_any_project?(:log_time)
      end
    end
  end
end
