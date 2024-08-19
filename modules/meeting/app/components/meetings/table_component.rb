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
  class TableComponent < ::TableComponent
    options :current_project # used to determine if displaying the projects column

    sortable_columns :title, :project_name, :type, :start_time, :duration, :location

    def initial_sort
      %i[start_time asc]
    end

    def sortable_columns_correlation
      super.merge(
        project_name: "projects.name",
        type: "meetings.type"
      )
    end

    def initialize_sorted_model
      helpers.sort_clear

      super
    end

    def paginated?
      true
    end

    def headers
      @headers ||= [
        [:title, { caption: Meeting.human_attribute_name(:title) }],
        current_project.blank? ? [:project_name, { caption: Meeting.human_attribute_name(:project) }] : nil,
        [:type, { caption: Meeting.human_attribute_name(:type) }],
        [:start_time, { caption: Meeting.human_attribute_name(:start_time) }],
        [:duration, { caption: Meeting.human_attribute_name(:duration) }],
        [:location, { caption: Meeting.human_attribute_name(:location) }]
      ].compact
    end

    def columns
      @columns ||= headers.map(&:first)
    end
  end
end
