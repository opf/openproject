# -- copyright
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
# ++
module Meetings
  class Menu < Submenu
    attr_reader :view_type, :project

    def initialize(project: nil, params: nil)
      @project = project
      @params = params

      super(view_type:, project:, params:)
    end

    def menu_items
      [
        OpenProject::Menu::MenuGroup.new(header: nil, children: top_level_menu_items),
        OpenProject::Menu::MenuGroup.new(header: I18n.t(:label_involvement), children: involvement_sidebar_menu_items)
      ]
    end

    def top_level_menu_items
      upcoming_filter = [{ time: { operator: "=", values: ["future"] } }].to_json
      past_filter = [{ time: { operator: "=", values: ["past"] } }].to_json

      [
        menu_item(title: I18n.t(:label_upcoming_meetings),
                  query_params: { filters: upcoming_filter, sort: "start_time" }),
        menu_item(title: I18n.t(:label_past_meetings),
                  query_params: { filters: past_filter, sort: "start_time:desc" })
      ]
    end

    def involvement_sidebar_menu_items
      [
        menu_item(title: I18n.t(:label_upcoming_invitations)),
        menu_item(title: I18n.t(:label_past_invitations),
                  query_params: { filters: past_filter, sort: "start_time:desc" }),
        menu_item(title: I18n.t(:label_attendee),
                  query_params: { filters: attendee_filter }),
        menu_item(title: I18n.t(:label_author),
                  query_params: { filters: author_filter })
      ]
    end

    def query_path(query_params)
      if project.present?
        project_meetings_path(project, params.permit(query_params.keys).merge!(query_params))
      else
        meetings_path(params.permit(query_params.keys).merge!(query_params))
      end
    end

    def past_filter
      [
        { time: { operator: "=", values: ["past"] } },
        { invited_user_id: { operator: "=", values: [User.current.id.to_s] } }
      ].to_json
    end

    def attendee_filter
      [{ attended_user_id: { operator: "=", values: [User.current.id.to_s] } }].to_json
    end

    def author_filter
      [{ author_id: { operator: "=", values: [User.current.id.to_s] } }].to_json
    end
  end
end
