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

module Redmine::MenuManager::TopMenu::HelpMenu
  def render_help_top_menu_node(item = help_menu_item)
    cache_key = ["help_top_menu_node",
                 OpenProject::Static::Links.cache_key,
                 I18n.locale,
                 OpenProject::Static::Links.help_link,
                 EnterpriseToken.active?]
    OpenProject::Cache.fetch(cache_key) do
      if OpenProject::Static::Links.help_link_overridden?
        render(Primer::Beta::IconButton.new(icon: item.icon,
                                            tag: :a,
                                            href: url_for(item.url),
                                            classes: "op-app-header--primer-button",
                                            scheme: :invisible,
                                            pl: 1,
                                            test_selector: "header-help-button",
                                            aria: { label: I18n.t(:label_help) },
                                            data: { allow_external_link: true },
                                            **item.html_options))
      else
        render_help_dropdown
      end
    end
  end

  def help_menu_item
    split_top_menu_into_main_or_more_menus[:help]
  end

  def render_help_dropdown
    render Primer::Alpha::ActionMenu.new(classes: "op-app-menu--item",
                                         menu_id: "op-app-header--help-menu",
                                         pl: 1,
                                         anchor_align: :end) do |menu|
      menu.with_show_button(icon: :question,
                            scheme: :invisible,
                            classes: "op-app-header--primer-button",
                            test_selector: "header-help-button",
                            "aria-label": I18n.t(:label_help))

      add_onboarding_item(menu)
      menu.with_divider
      add_help_and_support_items(menu)
      menu.with_divider
      add_additional_help_items(menu)
    end
  end

  private

  def add_onboarding_item(menu)
    menu.with_group do |menu_group|
      menu_group.with_heading(title: I18n.t("top_menu.getting_started"))

      menu_group.with_item(
        href: onboarding_video_dialog_path,
        label: t(:label_introduction_video),
        content_arguments: {
          target: "_top",
          data: { controller: "async-dialog" }
        },
        test_selector: "op-menu--item-action"
      )
    end
  end

  def add_help_and_support_items(menu) # rubocop:disable Metrics/AbcSize
    menu.with_group do |menu_group|
      menu_group.with_heading(title: I18n.t("top_menu.help_and_support"))

      unless EnterpriseToken.hide_banners? && EnterpriseToken.active?
        menu_group.with_item(
          **link_options_for(:upsell,
                             url_params: {
                               utm_source: "unknown",
                               utm_medium: "op-instance",
                               utm_campaign: "ee-upsell-help-menu"
                             })
        )
      end
      menu_group.with_item(**link_options_for(:user_guides))
      menu_group.with_item(href: OpenProject::Configuration.youtube_channel,
                           label: t(:label_videos),
                           content_arguments: {
                             target: "_blank",
                             rel: "noopener",
                             data: { allow_external_link: true }
                           },
                           test_selector: "op-menu--item-action")
      menu_group.with_item(**link_options_for(:shortcuts))
      menu_group.with_item(**link_options_for(:forums))
      menu_group.with_item(**link_options_for(
        EnterpriseToken.active? ? :enterprise_support : :enterprise_support_as_community
      ))
    end
  end

  def add_additional_help_items(menu) # rubocop:disable Metrics/AbcSize
    menu.with_group do |menu_group|
      menu_group.with_heading(title: I18n.t("top_menu.additional_resources"))

      if OpenProject::Static::Links.has? :impressum
        menu_group.with_item(**link_options_for(:impressum))
      end

      menu_group.with_item(**link_options_for(:data_privacy))
      menu_group.with_item(**link_options_for(:digital_accessibility))
      menu_group.with_item(**link_options_for(
        :website,
        url_params: {
          utm_source: "unknown",
          utm_medium: "op-instance",
          utm_campaign: "website-help-menu"
        }
      ))
      menu_group.with_item(**link_options_for(
        :security_alerts,
        url_params: {
          utm_source: "unknown",
          utm_medium: "op-instance",
          utm_campaign: "security-help-menu"
        }
      ))
      menu_group.with_item(**link_options_for(
        :newsletter,
        url_params: {
          utm_source: "unknown",
          utm_medium: "op-instance",
          utm_campaign: "newsletter-help-menu"
        }
      ))
      menu_group.with_item(**link_options_for(:blog))
      menu_group.with_item(**link_options_for(:release_notes))
      menu_group.with_item(**link_options_for(:report_bug))
      menu_group.with_item(**link_options_for(:roadmap))
      menu_group.with_item(**link_options_for(:crowdin))
      menu_group.with_item(**link_options_for(:api_docs))
    end
  end

  def link_options_for(key, options = {})
    href = OpenProject::Static::Links.url_for(key, url_params: options[:url_params] || {})
    label = OpenProject::Static::Links.label_for(key)

    {
      href: href,
      label: label,
      content_arguments: {
        target: "_blank",
        rel: "noopener",
        data: { allow_external_link: true }
      }
    }
  end
end
