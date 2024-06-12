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
    include Rails.application.routes.url_helpers

    attr_reader :controller_path, :params, :current_user

    def initialize(controller_path:, params:, current_user:)
      # rubocop:disable Rails/HelperInstanceVariable
      @controller_path = controller_path
      @params = params
      @current_user = current_user
      # rubocop:enable Rails/HelperInstanceVariable
    end

    def first_level_menu_items
      [
        OpenProject::Menu::MenuGroup.new(header: nil,
                                         children: [inbox_menu]),
        OpenProject::Menu::MenuGroup.new(header: I18n.t("js.notifications.menu.by_reason"),
                                         children: reason_filters),
        OpenProject::Menu::MenuGroup.new(header: I18n.t("js.notifications.menu.by_project"),
                                         children: project_filters),
      ]
    end

    private

    def inbox_menu
      OpenProject::Menu::MenuItem.new(title: I18n.t("js.notifications.menu.inbox"),
                                      icon: :inbox,
                                      href: notifications_path,
                                      selected: !(params[:name] && params[:filter]))
    end

    def selected?(filter, name)
      params[:filter] == filter && params[:name] == name
    end

    def reason_filters
      [
        OpenProject::Menu::MenuItem.new(title: I18n.t('js.notifications.menu.mentioned'),
                                        icon: :mention,
                                        href: notifications_path(filter: 'reason', name: 'mentioned'),
                                        selected: selected?('reason', 'mentioned')),
        OpenProject::Menu::MenuItem.new(title: I18n.t('js.label_assignee'),
                                        icon: :assigned,
                                        href: notifications_path(filter: 'reason', name: 'assigned'),
                                        selected: selected?('reason', 'assigned')),
        OpenProject::Menu::MenuItem.new(title: I18n.t('js.notifications.menu.accountable'),
                                        icon: :accountable,
                                        href: notifications_path(filter: 'reason', name: 'responsible'),
                                        selected: selected?('reason', 'responsible')),
        OpenProject::Menu::MenuItem.new(title: I18n.t('js.notifications.menu.watched'),
                                        icon: :watching,
                                        href: notifications_path(filter: 'reason', name: 'watched'),
                                        selected: selected?('reason', 'watched')),
        OpenProject::Menu::MenuItem.new(title: I18n.t('js.notifications.menu.date_alert'),
                                        icon: :"date-alert", # TODO ee icon
                                        href: notifications_path(filter: 'reason', name: 'dateAlert'),
                                        selected: selected?('reason', 'dateAlert')),
        OpenProject::Menu::MenuItem.new(title: I18n.t('js.notifications.menu.shared'),
                                        icon: :share, # TODO ee icon
                                        href: notifications_path(filter: 'reason', name: 'shared'),
                                        selected: selected?('reason', 'shared')),
      ]
    end

    def project_filters
      # TODO
      []
    end

  end
end
