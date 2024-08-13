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

module Notifications
  class Menu < Submenu
    ENTERPRISE_REASONS = %w[shared date_alert].freeze

    include Rails.application.routes.url_helpers

    attr_reader :params, :current_user,
                :query, :unread, :unread_by_reason, :unread_by_project

    def initialize(params:, current_user:)
      @params = params
      @current_user = current_user
      @unread = filter_unread
      @unread_by_reason = filter_unread_by_reason
      @unread_by_project = filter_unread_by_project

      super(view_type: nil, project: nil, params:)
    end

    def menu_items
      [
        OpenProject::Menu::MenuGroup.new(header: nil, children: [inbox_menu]),
        OpenProject::Menu::MenuGroup.new(header: I18n.t("notifications.menu.by_reason"),
                                         children: reason_filters),
        OpenProject::Menu::MenuGroup.new(header: I18n.t("notifications.menu.by_project"),
                                         children: project_filters)
      ]
    end

    private

    def inbox_menu
      count = unread
      menu_item(title: I18n.t("notifications.menu.inbox"), icon_key: :inbox, count: count == 0 ? nil : count)
    end

    def reason_filters
      %w[mentioned assigned responsible watched dateAlert shared].map do |reason|
        count = unread_by_reason[reason]
        menu_item(title: I18n.t("notifications.reasons.#{reason}"),
                  icon_key: reason,
                  count: count == 0 ? nil : count,
                  query_params: query_params("reason", reason),
                  show_enterprise_icon: show_enterprise_icon?(reason))
      end
    end

    def project_filters
      unread_by_project.map do |project, count|
        menu_item(title: (project.parent.present? ? "... " : "") + project.name,
                  count:,
                  query_params: query_params("project", project.id))
      end
    end

    def base_query
      Queries::Notifications::NotificationQuery.new(user: current_user)
                                               .where(:read_ian, "=", "f")
    end

    def filter_unread
      query = base_query
      query.results.count
    end

    def filter_unread_by_reason
      query = base_query
      query.group(:reason)
      query.group_values
    end

    def filter_unread_by_project
      query = base_query
      query.group(:project)
      query.group_values
    end

    def query_params(filter, name)
      { filter:, name: }
    end

    def selected?(query_params)
      params[:filter] == query_params[:filter] && params[:name] == query_params[:name].to_s
    end

    def query_path(query_params)
      if query_params[:name] == "shared" && show_enterprise_icon?("shared")
        return notifications_share_upsale_path(query_params)
      elsif query_params[:name] == "dateAlert" && show_enterprise_icon?("dateAlert")
        return notifications_date_alert_upsale_path(query_params)
      end

      notifications_center_path(query_params)
    end

    def icon_map
      {
        "mentioned" => :mention,
        "assigned" => :"op-person-assigned",
        "responsible" => :"op-person-accountable",
        "watched" => :eye,
        "shared" => :"share-android",
        "dateAlert" => :"op-calendar-alert"
      }
    end

    def show_enterprise_icon?(reason)
      if reason == "shared"
        !EnterpriseToken.allows_to?(:work_package_sharing)
      elsif reason == "dateAlert"
        !EnterpriseToken.allows_to?(:date_alerts)
      else
        false
      end
    end
  end
end
