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
  module Widgets
    class Meetings < Grids::WidgetComponent
      MEETINGS_LIMIT = 5
      private_constant :MEETINGS_LIMIT

      param :project, optional: true

      option :limit, default: -> { MEETINGS_LIMIT }

      def next_meetings
        @next_meetings ||= meetings.limit(limit).to_a
      end

      def meetings
        @meetings ||=
          if project_scoped?
            project
              .meetings
              .visible(current_user)
              .participated_by(current_user)
              .upcoming
          else
            ::Meeting
              .visible(current_user)
              .participated_by(current_user)
              .upcoming
              .includes(:project)
          end
      end

      def title
        t(:label_my_meetings)
      end

      def render?
        current_user.logged? && (global_scoped? || project.module_enabled?("meetings"))
      end

      private

      def project_scoped? = project.present?

      def global_scoped? = !project_scoped?

      def can_manage_meetings?
        if project_scoped?
          current_user.allowed_in_project?(:create_meetings, project)
        else
          current_user.allowed_in_any_project?(:create_meetings)
        end
      end

      def details_row_string(meeting)
        details = []
        details << helpers.format_time(meeting.start_time)
        if meeting.duration.present?
          details << meeting_duration(meeting)
        end
        details << "#{t(:label_project).capitalize}: #{meeting.project.name}" if global_scoped?
        details.join(", ")
      end

      def new_meetings_link
        if global_scoped?
          new_dialog_meetings_path
        else
          new_dialog_project_meetings_path(project)
        end
      end

      def all_meetings_link
        if global_scoped?
          meetings_path
        else
          project_meetings_path(project)
        end
      end

      def meeting_duration(meeting)
        OpenProject::Common::DurationComponent.new(meeting.duration, :hours, abbreviated: true).text
      end
    end
  end
end
