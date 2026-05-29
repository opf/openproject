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

module Redmine::MenuManager::TopMenuHelper
  include Redmine::MenuManager::TopMenu::HelpMenu
  include Redmine::MenuManager::TopMenu::ProjectsMenu
  include Redmine::MenuManager::TopMenu::QuickAddMenu
  include Redmine::MenuManager::TopMenu::UserMenu
  include Redmine::MenuManager::TopMenu::ModuleMenu

  def render_top_menu_left
    tag.nav class: "op-app-menu op-app-menu_drop-left", aria: { label: t(:label_top_menu) } do
      safe_join top_menu_left_menu_items
    end
  end

  def top_menu_left_menu_items
    items = [
      render_module_top_menu_node,
      render_logo
    ]

    cs = CustomStyle.current
    if cs&.logo_mobile.present? || !custom_logo?
      items << render_logo_icon
    end

    items
  end

  def render_top_menu_center
    render_top_menu_search
  end

  def render_logo
    mode_class = "op-logo--link_high_contrast" if User.current.pref.light_high_contrast_theme?
    content_tag :div, class: "op-logo" do
      link_to(I18n.t("label_home"),
              configurable_home_url,
              data: { auto_theme_switcher_target: "desktopLogo", controller: "mngt--logo-skeleton" },
              class: ["op-logo--link", "op-logo--loading", mode_class].compact)
    end
  end

  def render_logo_icon
    mode_class = "op-logo--icon_white" unless User.current.pref.light_high_contrast_theme?
    link_to(I18n.t("label_home"),
            configurable_home_url,
            data: { auto_theme_switcher_target: "mobileLogo" },
            class: ["op-logo", "op-logo--icon", "op-logo--link", mode_class].compact)
  end

  def render_waffle_menu_logo_icon
    style = CustomStyle.current
    classes = ["op-logo"]
    if style&.logo_mobile.present?
      classes << "op-logo--icon"
    else
      mode_class = User.current.pref.theme == "dark" ? "op-logo--icon_white" : "op-logo--icon"
      classes << mode_class
    end
    render Primer::BaseComponent.new(tag: :div, classes:)
  end

  def render_top_menu_search
    content_tag :div, class: "op-app-search" do
      render_global_search_input
    end
  end

  def render_top_menu_teaser
    if User.current.admin? && EnterpriseToken.trial_only?
      render(Primer::BaseComponent.new(tag: :div, classes: "op-app-menu--item hidden-for-mobile")) do
        render(EnterpriseEdition::BuyNowButtonComponent.new)
      end
    end
  end

  def render_global_search_input
    angular_component_tag "opce-global-search",
                          inputs: {
                            placeholder: I18n.t("global_search.placeholder", app_title: Setting.app_title)
                          }
  end

  def render_top_menu_right
    capture do
      concat render_top_menu_teaser
      concat render_mngt_theme_toggle
      concat render_quick_add_menu
      concat render_notification_top_menu_node
      concat render_user_top_menu_node
    end
  end

  def render_mngt_theme_toggle
    return "".html_safe unless User.current.logged?

    current_theme = User.current.pref.theme.presence || "light"

    sun_icon = tag.svg(xmlns: "http://www.w3.org/2000/svg", viewBox: "0 0 16 16", width: "18", height: "18",
                       fill: "currentColor", class: "mngt-theme-icon mngt-theme-icon--sun",
                       aria: { hidden: true }) do
      tag.path(d: "M8 10.5a2.5 2.5 0 100-5 2.5 2.5 0 000 5zM8 12a4 4 0 100-8 4 4 0 000 8zM8 0a.75.75 0 01.75.75v1.5a.75.75 0 01-1.5 0V.75A.75.75 0 018 0zm0 13a.75.75 0 01.75.75v1.5a.75.75 0 01-1.5 0v-1.5A.75.75 0 018 13zm8-5a.75.75 0 01-.75.75h-1.5a.75.75 0 010-1.5h1.5A.75.75 0 0116 8zM3 8a.75.75 0 01-.75.75H.75a.75.75 0 010-1.5h1.5A.75.75 0 013 8zm10.657-5.657a.75.75 0 010 1.06l-1.061 1.06a.75.75 0 11-1.06-1.06l1.06-1.06a.75.75 0 011.061 0zm-9.193 9.193a.75.75 0 010 1.06l-1.06 1.061a.75.75 0 11-1.061-1.06l1.06-1.061a.75.75 0 011.061 0zm9.193 2.121a.75.75 0 01-1.06 0l-1.061-1.06a.75.75 0 111.06-1.061l1.061 1.06a.75.75 0 010 1.061zM4.464 4.464a.75.75 0 01-1.06 0L2.343 3.404a.75.75 0 111.06-1.06l1.061 1.06a.75.75 0 010 1.06z")
    end

    moon_icon = tag.svg(xmlns: "http://www.w3.org/2000/svg", viewBox: "0 0 16 16", width: "18", height: "18",
                        fill: "currentColor", class: "mngt-theme-icon mngt-theme-icon--moon",
                        aria: { hidden: true }) do
      tag.path(d: "M9.598 1.591a.749.749 0 0 1 .785-.175 7 7 0 1 1-8.967 8.967.75.75 0 0 1 .961-.96 5.5 5.5 0 0 0 7.046-7.046.75.75 0 0 1 .175-.786Zm1.616 1.945a7 7 0 0 1-7.678 7.678 5.499 5.499 0 1 0 7.678-7.678Z")
    end

    button = tag.button(
      sun_icon + moon_icon,
      class: "mngt-theme-toggle-btn",
      "data-action": "click->mngt--theme-toggle#toggle",
      "aria-label": current_theme == "dark" ? "Mudar para modo claro" : "Mudar para modo escuro"
    )

    tag.div(button,
            class: "op-app-menu--item mngt-theme-toggle-wrapper",
            "data-controller": "mngt--theme-toggle",
            "data-mngt--theme-toggle-theme-value": current_theme)
  end

  private

  def render_notification_top_menu_node
    return "".html_safe unless User.current.logged?
    return "".html_safe if Setting.notifications_hidden?

    render(Primer::BaseComponent.new(tag: :div,
                                     classes: "op-app-menu--item",
                                     position: :relative,
                                     px: 1)) do
      concat(render(Primer::Beta::IconButton.new(icon: :inbox,
                                                 tag: :a,
                                                 href: notifications_path,
                                                 classes: "op-app-header--primer-button op-ian-bell",
                                                 scheme: :invisible,
                                                 test_selector: "op-ian-bell",
                                                 aria: { label: I18n.t(:label_notification_center_plural) })))
      concat(angular_component_tag("opce-in-app-notification-bell",
                                   inputs: {
                                     interval: Setting.notifications_polling_interval
                                   }))
    end
  end

  # Split the :top_menu into separate :main and :modules items
  def split_top_menu_into_main_or_more_menus
    @split_top_menu_into_main_or_more_menus ||= begin
      items = Hash.new { |h, k| h[k] = [] }
      first_level_menu_items_for(:top_menu) do |item|
        if item.name == :help
          items[:help] = item
        else
          context = item.context || :modules
          items[context] << item
        end
      end
      items
    end
  end
end
