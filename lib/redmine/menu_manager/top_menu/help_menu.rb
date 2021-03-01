#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module Redmine::MenuManager::TopMenu::HelpMenu
  def render_help_top_menu_node(item = help_menu_item)
    cache_key = ['help_top_menu_node',
                 OpenProject::Static::Links.links,
                 I18n.locale,
                 OpenProject::Static::Links.help_link]

    OpenProject::Cache.fetch(cache_key) do
      if OpenProject::Static::Links.help_link_overridden?
        render_menu_node(item)
        content_tag('li', render_single_menu_node(item), class: 'help-menu--overridden-link')
      else
        render_help_dropdown
      end
    end
  end

  def render_help_dropdown
    link_to_help_pop_up = link_to '',
                                  title: I18n.t(:label_help),
                                  class: 'top-menu-dropdown--link',
                                  aria: { haspopup: 'true' } do
      op_icon('icon-help top-menu-help--icon')
    end

    render_menu_dropdown(
      link_to_help_pop_up,
      menu_item_class: 'hidden-for-mobile top-menu-help',
      drop_down_class: 'top-menu-help--dropdown'
    ) do
      result = ''.html_safe
      render_onboarding result
      render_help_and_support result
      render_additional_resources result

      result
    end
  end

  private

  def render_onboarding(result)
    result << content_tag(:li) do
      content_tag(:span, I18n.t('top_menu.getting_started'),
                  class: 'top-menu-dropdown--headline',
                  title: I18n.t('top_menu.getting_started'))
    end
    result << render_onboarding_menu_item
    result << content_tag(:hr, '', class: 'top-menu-dropdown--separator')
  end

  def render_onboarding_menu_item
    controller.render_to_string(partial: 'onboarding/menu_item')
  end

  def render_help_and_support(result)
    result << content_tag(:li) do
      content_tag :span, I18n.t('top_menu.help_and_support'),
                  class: 'top-menu-dropdown--headline',
                  title: I18n.t('top_menu.help_and_support')
    end
    if EnterpriseToken.show_banners?
      result << static_link_item(:upsale,
                                 href_suffix: "/?utm_source=unknown&utm_medium=op-instance&utm_campaign=ee-upsale-help-menu")
    end
    result << static_link_item(:user_guides)
    result << content_tag(:li) do
      link_to I18n.t('label_videos'),
              OpenProject::Configuration.youtube_channel,
              title: I18n.t('label_videos'),
              target: '_blank'
    end
    result << static_link_item(:shortcuts)
    result << static_link_item(:forums)
    result << static_link_item(:professional_support)
    result << content_tag(:hr, '', class: 'top-menu-dropdown--separator')
  end

  def render_additional_resources(result)
    result << content_tag(:li) do
      content_tag :span,
                  I18n.t('top_menu.additional_resources'),
                  class: 'top-menu-dropdown--headline',
                  title: I18n.t('top_menu.additional_resources')
    end

    if OpenProject::Static::Links.has? :impressum
      result << static_link_item(:impressum)
    end

    result << static_link_item(:data_privacy)
    result << static_link_item(
      :website,
      href_suffix: "/?utm_source=unknown&utm_medium=op-instance&utm_campaign=website-help-menu"
    )
    result << static_link_item(
      :newsletter,
      href_suffix: "/?utm_source=unknown&utm_medium=op-instance&utm_campaign=newsletter-help-menu"
    )
    result << static_link_item(:blog)
    result << static_link_item(:release_notes)
    result << static_link_item(:report_bug)
    result << static_link_item(:roadmap)
    result << static_link_item(:crowdin)
    result << static_link_item(:api_docs)
  end

  def static_link_item(key, options = {})
    link = OpenProject::Static::Links.links[key]
    label = I18n.t(link[:label])
    content_tag(:li) do
      link_to label, "#{link[:href]}#{options[:href_suffix]}", title: label, target: '_blank'
    end
  end
end
