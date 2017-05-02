#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'concerns/omniauth_login'
require 'open_project/static/links'

module Redmine::MenuManager::TopMenu::HelpMenu
  def render_help_top_menu_node(item = help_menu_item)
    cache_key = OpenProject::Cache::CacheKey.key('help_top_menu_node',
                                                 I18n.locale,
                                                 OpenProject::Static::Links.help_link)
    Rails.cache.fetch(cache_key) do
      if OpenProject::Static::Links.help_link_overridden?
        render_menu_node(item)
      else
        render_help_dropdown
      end
    end
  end

  def render_help_dropdown
    link_to_help_pop_up = link_to '',
                                  title: l(:label_help),
                                  class: 'menu-item--help',
                                  aria: { haspopup: 'true' } do
      op_icon('icon-help')
    end

    render_menu_dropdown(
      link_to_help_pop_up,
      menu_item_class: 'hidden-for-mobile',
      drop_down_class: 'drop-down--help'
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
      content_tag(:span, l('top_menu.getting_started'),
                  class: 'drop-down--help-headline',
                  title: l('top_menu.getting_started'))
    end
    result << render_onboarding_menu_item
    result << content_tag(:hr, '', class: 'form--separator')
  end

  def render_onboarding_menu_item
    render_to_string(partial: 'onboarding/menu_item')
  end

  def render_help_and_support(result)
    result << content_tag(:li) do
      content_tag :span, l('top_menu.help_and_support'),
                  class: 'drop-down--help-headline',
                  title: l('top_menu.help_and_support')
    end
    if EnterpriseToken.show_banners?
      result << static_link_item(:upsale, href_suffix: "?utm_source=ce-helpmenu")
    end
    result << static_link_item(:user_guides)
    result << content_tag(:li) {
      link_to l('homescreen.links.shortcuts'),
              '',
              title: l('homescreen.links.shortcuts'),
              onClick: 'modalHelperInstance.createModal(\'/help/keyboard_shortcuts\');'
    }
    result << static_link_item(:boards)
    result << static_link_item(:professional_support)
    result << content_tag(:hr, '', class: 'form--separator')
  end

  def render_additional_resources(result)
    result << content_tag(:li) do
      content_tag :span,
                  l('top_menu.additional_resources'),
                  class: 'drop-down--help-headline',
                  title: l('top_menu.additional_resources')
    end
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
      link_to label, "#{link[:href]}#{options[:href_suffix]}", title: label
    end
  end
end
