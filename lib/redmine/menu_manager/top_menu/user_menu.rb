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

module Redmine::MenuManager::TopMenu::UserMenu
  def render_user_top_menu_node(items = first_level_menu_items_for(:account_menu))
    if omniauth_direct_login? && !User.current.logged?
      render_direct_login
    else
      render_user_drop_down items
    end
  end

  private

  def render_direct_login
    render(Primer::Beta::IconButton.new(icon: "person",
                                        tag: :a,
                                        scheme: :invisible,
                                        href: signin_path,
                                        classes: "op-app-menu--item op-app-header--primer-button",
                                        aria: { label: I18n.t(:label_login) }))
  end

  def render_user_drop_down(items)
    avatar = avatar(
      User.current,
      class: "op-top-menu-user-avatar",
      hover_card: { active: false },
      avatar_image_alt_text: I18n.t("label_user_menu")
    )

    render Primer::Alpha::Dialog.new(title: I18n.t("label_user_menu"),
                                     visually_hide_title: true,
                                     size: User.current.logged? ? :small : :medium,
                                     position: :right) do |dialog|
      lateral_user_menu_button(dialog, avatar)

      dialog.with_header(classes: "op-app-header--modules-menu-header") do
        lateral_user_menu_header(avatar)
      end

      dialog.with_body do
        if User.current.logged?
          lateral_user_menu_body(items)
        else
          render_login_partial
        end
      end
    end
  end

  def lateral_user_menu_button(dialog, avatar)
    options = {
      scheme: :invisible,
      classes: "op-app-header--primer-button op-app-menu--item",
      test_selector: "op-app-header--user-menu-button"
    }

    if User.current.logged?
      if avatar.present?
        dialog.with_show_button(px: 0, **options) do |button|
          button.with_tooltip(text: I18n.t("label_user_menu"))
          avatar
        end
      else
        dialog.with_show_button(icon: :person, aria: { label: I18n.t("label_user_menu") }, **options) do |button|
          button.with_tooltip(text: I18n.t("label_user_menu"))
        end
      end
    else
      dialog.with_show_button(px: 1, **options) do |button|
        button.with_trailing_visual_icon(icon: :"triangle-down")
        t(:label_login)
      end
    end
  end

  def lateral_user_menu_header(avatar)
    render(Primer::OpenProject::FlexLayout.new(align_items: :center)) do |flex|
      flex.with_column(mr: 2) do
        if show_avatar?(avatar)
          avatar
        else
          render(Primer::Beta::Octicon.new(icon: :person, aria: { label: I18n.t("label_user_menu") }))
        end
      end
      flex.with_column(font_weight: :bold) do
        User.current.logged? ? User.current.name : I18n.t(:label_login)
      end
    end
  end

  def lateral_user_menu_body(items)
    partial_items, link_items = items.partition { |item| item.partial.present? }

    render(Primer::OpenProject::FlexLayout.new) do |flex|
      partial_items.each do |item|
        flex.with_row(mb: 2) do
          render partial: item.partial
        end
      end
      flex.with_row do
        render Primer::Alpha::ActionList.new(
          classes: "op-app-menu--items",
          id: "op-app-header--user-menu-list"
        ) do |list|
          list.with_divider

          add_lateral_user_menu_items list, link_items
        end
      end
    end
  end

  def add_lateral_user_menu_items(list, link_items)
    link_items.each do |item|
      list.with_divider if item.show_divider_before?

      list.with_item(
        href: allowed_node_url(item, nil),
        label: item.caption,
        scheme: item.scheme || :default,
        test_selector: "op-menu--item-action",
        **item.html_options
      ) do |menu_item|
        menu_item.with_leading_visual_icon(icon: item.icon) if item.icon
      end
    end
  end

  def render_login_partial
    partial =
      if OpenProject::Configuration.disable_password_login?
        "account/omniauth_login"
      else
        "account/login"
      end

    render partial:
  end

  def show_avatar?(avatar)
    User.current.logged? && avatar.present?
  end
end
