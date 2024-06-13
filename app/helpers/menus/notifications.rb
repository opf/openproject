#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module Menus
  class Notifications
    ENTERPRISE_REASONS = %w[shared date_alert].freeze

    include Rails.application.routes.url_helpers

    attr_reader :controller_path, :params, :current_user,
                :query, :unread_by_reasons, :unread_by_projects

    def initialize(controller_path:, params:, current_user:)
      # rubocop:disable Rails/HelperInstanceVariable
      @controller_path = controller_path
      @params = params
      @current_user = current_user
      @unread_by_reasons = filter_unread_by_reason
      # rubocop:enable Rails/HelperInstanceVariable
    end

    def first_level_menu_items
      [
        OpenProject::Menu::MenuGroup.new(header: nil,
                                         children: [inbox_menu]),
        OpenProject::Menu::MenuGroup.new(header: I18n.t("notifications.menu.by_reason"),
                                         children: reason_filters),
        OpenProject::Menu::MenuGroup.new(header: I18n.t("notifications.menu.by_project"),
                                         children: project_filters),
      ]
    end

    private

    def filter_unread_by_reason
      query = Queries::Notifications::NotificationQuery.new(user: current_user)
      query.where(:read_ian, "=", "f")
      query.group(:reason)
      counts = query.group_values

      # combine start and due alerts
      counts["date_alert"] = [counts["date_alert_start_date"], counts["date_alert_due_date"]].sum(&:to_i)

      counts
    end

    def inbox_menu
      OpenProject::Menu::MenuItem.new(title: I18n.t("notifications.menu.inbox"),
                                      icon: :inbox,
                                      href: notifications_path,
                                      selected: !(params[:name] && params[:filter]))
    end

    def selected?(filter, name)
      params[:filter] == filter && params[:name] == name
    end

    def reason_filters
      %w[mentioned assigned responsible watched date_alert shared].map do |reason|
        count = unread_by_reasons[reason]
        OpenProject::Menu::MenuItem.new(title: I18n.t("mail.work_packages.reason.#{reason}"),
                                        icon: icon_map.fetch(reason, reason),
                                        href: notifications_path(filter: "reason", name: reason),
                                        count: count == 0 ? nil : count,
                                        selected: selected?("reason", reason))
      end
    end

    def project_filters
      # TODO
      []
    end

    def icon_map
      {
        "mentioned" => :mention,
        "responsible" => :accountable,
        "watched" => :watching,
        "shared" => :share,
        "date_alert" => :"date-alert"
      }
    end
  end
end
