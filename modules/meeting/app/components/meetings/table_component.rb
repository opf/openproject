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

module Meetings
  class TableComponent < ::OpPrimer::BorderBoxTableComponent
    options :current_project # used to determine if displaying the projects column

    columns :title, :start_time, :project_name, :duration, :location, :frequency

    mobile_columns :title, :start_time, :project_name

    mobile_labels :project_name

    main_column :title

    def sortable?
      false
    end

    def paginated?
      false
    end

    def has_footer?
      model.is_a?(ActiveRecord::Relation) &&
        (model.total_entries > model.size)
    end

    def footer
      render Meetings::TableFooterComponent.new(
        upcoming: options[:upcoming],
        total: model.total_entries,
        count: model.size
      )
    end

    def has_actions?
      true
    end

    def mobile_title
      I18n.t(:label_meeting_plural)
    end

    def headers
      @headers ||= [
        [:title, { caption: Meeting.human_attribute_name(:title) }],
        recurring? ? [:frequency, { caption: I18n.t("activerecord.attributes.recurring_meeting.frequency") }] : nil,
        [:start_time,
         { caption: recurring? ? I18n.t("activerecord.attributes.meeting.start_time") : I18n.t(:label_meeting_date_and_time) }],
        current_project.blank? ? [:project_name, { caption: Meeting.human_attribute_name(:project) }] : nil,
        [:duration, { caption: Meeting.human_attribute_name(:duration) }],
        [:location, { caption: Meeting.human_attribute_name(:location) }]
      ].compact
    end

    def columns
      @columns ||= headers.map(&:first)
    end

    def recurring?
      model.first.is_a?(RecurringMeeting)
    end

    def blank_title
      I18n.t("meeting.blankslate.title")
    end

    def blank_description
      I18n.t("meeting.blankslate.desc")
    end
  end
end
