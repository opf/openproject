# frozen_string_literal: true

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
    CROSS_FILTER_KEYS = %w[time project_id].freeze

    def initialize(params:, project: nil)
      super(view_type: nil, project:, params:)
    end

    def menu_items
      [
        OpenProject::Menu::MenuGroup.new(header: nil, children: top_level_menu_items),
        OpenProject::Menu::MenuGroup.new(header: I18n.t(:label_meeting_series), children: meeting_series_menu_items),
        involvement_group
      ].compact
    end

    def top_level_menu_items
      [
        my_meetings_item,
        recurring_menu_item,
        all_meetings_item,
        templates_menu_item
      ].compact
    end

    def my_meetings_item
      return unless User.current.logged?

      menu_item(title: I18n.t(:label_my_meetings), selected: my_meetings_selected?)
    end

    def my_meetings_selected?
      return false unless params[:current_href] == polymorphic_path([project, :meetings])
      return params[:filters].blank? if preset_filters.empty?

      sole_preset_matches?("invited_user_id", "=", [User.current.id.to_s])
    end

    def templates_menu_item
      return unless User.current.logged?
      return unless can_create_meetings?

      templates_href = if project
                         templates_project_meetings_path(project)
                       else
                         templates_meetings_path
                       end
      menu_item(
        title: I18n.t(:label_meeting_templates),
        href: templates_href,
        selected: params[:current_href] == templates_href,
        show_enterprise_icon: !EnterpriseToken.allows_to?(:meeting_templates)
      )
    end

    def all_meetings_item
      all_filter = [{ time: { operator: Queries::Operators::Upcoming.symbol, values: [] } }].to_json

      menu_item(title: I18n.t(:label_all_meetings),
                selected: all_meetings_selected?,
                query_params: { filters: all_filter })
    end

    def all_meetings_selected?
      preset_filters.empty? && (User.current.anonymous? || params[:filters].present?)
    end

    def meeting_series_menu_items # rubocop:disable Metrics/AbcSize
      all_series = RecurringMeeting
        .visible
        .includes(:project)
        .reorder("LOWER(title)")

      if project
        all_series = all_series.where(project_id: project.id)
      end

      current_href = params[:current_href]
      current_recurring_meeting_id = extracted_series_id(current_href)

      all_series.all.map do |series|
        href = project_recurring_meeting_path(series.project, series)
        OpenProject::Menu::MenuItem.new(title: series.title,
                                        selected: select_status(href, current_href, current_recurring_meeting_id),
                                        href:)
      end
    end

    def recurring_menu_item
      recurring_filter = [
        { type: { operator: "=", values: ["t"] } },
        { time: { operator: Queries::Operators::Upcoming.symbol, values: [] } }
      ].to_json

      menu_item(title: I18n.t("label_recurring_meeting_plural"),
                selected: recurring_meetings_selected?,
                query_params: { filters: recurring_filter, sort: "start_time" })
    end

    def recurring_meetings_selected?
      sole_preset_matches?("type", "=", [OpenProject::Database::DB_VALUE_TRUE])
    end

    def sole_preset_matches?(key, operator, values)
      return false unless preset_filters.size == 1

      filter = preset_filters.first[key]
      filter.is_a?(Hash) && filter["operator"] == operator && filter["values"] == values
    end

    def preset_filters
      parsed_filters.reject { |filter| filter.keys.intersect?(CROSS_FILTER_KEYS) }
    end

    def parsed_filters
      return @parsed_filters if defined?(@parsed_filters)

      @parsed_filters = JSON.parse(params[:filters].to_s)
    rescue JSON::ParserError
      @parsed_filters = []
    end

    def involvement_group
      return unless User.current.logged?

      OpenProject::Menu::MenuGroup.new(header: I18n.t(:label_involvement), children: involvement_sidebar_menu_items)
    end

    def involvement_sidebar_menu_items
      [
        attended_menu_item,
        created_by_me_menu_item
      ]
    end

    def query_path(query_params)
      if project.present?
        project_meetings_path(project, params.permit(query_params.keys).merge!(query_params))
      else
        meetings_path(params.permit(query_params.keys).merge!(query_params))
      end
    end

    def attendee_filter
      [
        { attended_user_id: { operator: "=", values: [User.current.id.to_s] } },
        { time: { operator: Queries::Operators::Past.symbol, values: [] } }
      ].to_json
    end

    def author_filter
      [{ author_id: { operator: "=", values: [User.current.id.to_s] } }].to_json
    end

    def recurring_meeting_type_filter
      [{ type: { operator: "=", values: [RecurringMeeting.to_s] } }].to_json
    end

    def extracted_series_id(current_href)
      current_meeting_id = current_href.split("/").last.to_i if current_href&.match(/\/meetings\/\d+$/)

      Meeting.find_by(id: current_meeting_id)&.recurring_meeting_id if current_meeting_id
    end

    def select_status(href, current_href, current_recurring_meeting_id = nil)
      return current_href == href unless current_recurring_meeting_id && !href.is_a?(Hash)

      href_meeting_id = href.split("/").last.to_i

      current_recurring_meeting_id == href_meeting_id
    end

    private

    def attended_menu_item
      menu_item(
        title: I18n.t(:label_attended),
        query_params: { filters: attendee_filter },
        selected: params[:filters].to_s.include?("attended_user_id")
      )
    end

    def created_by_me_menu_item
      menu_item(
        title: I18n.t(:label_created_by_me),
        query_params: { filters: author_filter },
        selected: params[:filters].to_s.include?("author_id")
      )
    end

    def can_create_meetings?
      if project
        User.current.allowed_in_project?(:create_meetings, project)
      else
        User.current.allowed_in_any_project?(:create_meetings)
      end
    end
  end
end
