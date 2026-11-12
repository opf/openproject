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

module RecurringMeetings
  class TableComponent < ::OpPrimer::BorderBoxTableComponent
    options :current_project,
            :recurring_meeting,
            :count,
            :direction,
            :max_count,
            :hide_footer,
            :blankslate_title,
            :blankslate_desc

    columns :start_time, :relative_time, :status, :create

    mobile_columns :start_time, :status

    def has_actions?
      true
    end

    def has_footer?
      return false if options[:hide_footer]
      return true if options[:max_count].nil?

      options[:max_count] - count > 0
    end

    def footer
      render RecurringMeetings::FooterComponent.new(
        meeting: recurring_meeting,
        project: options[:current_project],
        direction: options[:direction],
        max_count: options[:max_count],
        count:
      )
    end

    def mobile_title
      I18n.t(:label_recurring_meeting_plural)
    end

    def headers
      @headers ||= [
        [:start_time, { caption: I18n.t(:label_meeting_date_and_time) }],
        [:relative_time, { caption: I18n.t("recurring_meeting.starts") }],
        [:status, { caption: Meeting.human_attribute_name(:status) }],
        [:create, { caption: "" }]
      ].compact
    end

    def columns
      @columns ||= headers.map(&:first)
    end

    def count
      @count ||= [options[:count], rows.count].max
    end

    def blankslate?
      options[:blankslate_title].present?
    end

    def render_blank_slate
      render(Primer::Beta::Blankslate.new(border: false)) do |component|
        component.with_visual_icon(icon: blank_icon, size: :medium) if blank_icon
        component.with_heading(tag: :h2) { blank_title }
        component.with_description { blank_description }
      end
    end

    def blank_title
      blankslate? ? options[:blankslate_title] : I18n.t(:label_nothing_display)
    end

    def blank_description
      blankslate? ? options[:blankslate_desc] : I18n.t(:no_results_title_text)
    end
  end
end
