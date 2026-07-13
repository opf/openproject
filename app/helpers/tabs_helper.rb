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

module TabsHelper
  # Renders tabs and their content
  def render_tabs(tabs, form = nil)
    if tabs.any?
      selected = selected_tab(tabs)
      render partial: "common/tabs", locals: { f: form, tabs:, selected_tab: selected }
    else
      content_tag "p", I18n.t(:label_no_data), class: "nodata"
    end
  end

  def render_tab_header_nav(header, tabs, test_selector: nil)
    return if tabs.blank?

    header.with_tab_nav(label: nil, test_selector:) do |tab_nav|
      tabs.each do |tab|
        tab_nav.with_tab(selected: selected_tab(tabs) == tab, href: tab[:path], data: tab[:data]) do |t|
          feature = tab[:enterprise_feature]

          if feature && !EnterpriseToken.allows_to?(feature)
            t.with_icon(icon: :"op-enterprise-addons", classes: "upsell-colored")
          end
          t.with_text { tab_label(tab) }
        end
      end
    end
  end

  def tab_label(tab)
    if tab[:label].is_a?(String)
      tab[:label]
    else
      I18n.t(tab[:label])
    end
  end

  def selected_tab(tabs)
    selected = tabs.detect { |t| t[:name].to_s == params[:tab].to_s } || tabs.detect { tab_route_shown?(it) }
    return selected unless selected.nil?

    tabs.first
  end

  def tabs_for_key(key, params = {})
    ::OpenProject::Ui::ExtensibleTabs.enabled_tabs(key, params.reverse_merge(current_user:)).map do |tab|
      path = tab[:path].respond_to?(:call) ? instance_exec(params, &tab[:path]) : tab[:path]
      tab.dup.merge(path:)
    end
  end

  def tab_route_shown?(tab)
    path = request&.path
    return false if path.blank?

    # Check not only for exact matches but also for sub-routes
    # The first test matches cases when the current path is a subset of the tab path, like edit routes:
    # Ex: /module_a/items/:id/edit matches /module_a/items/:id
    # The second test is the other way around, when the current path is a subset of the tab path, like hierarchy cf paths
    # /module_a/items & /module_a/items/:id

    tab[:path].starts_with?(path) || path.starts_with?(tab[:path])
  end
end
