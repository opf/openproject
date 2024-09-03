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
  def render_tabs(tabs, form = nil, with_tab_nav: true)
    if tabs.any?
      selected = selected_tab(tabs)
      render partial: "common/tabs", locals: { f: form, tabs:, selected_tab: selected, with_tab_nav: }
    else
      content_tag "p", I18n.t(:label_no_data), class: "nodata"
    end
  end

  def selected_tab(tabs)
    tabs.detect { |t| t[:name] == params[:tab] } || tabs.first
  end

  def tabs_for_key(key, params = {})
    ::OpenProject::Ui::ExtensibleTabs.enabled_tabs(key, params.reverse_merge(current_user:)).map do |tab|
      path = tab[:path].respond_to?(:call) ? instance_exec(params, &tab[:path]) : tab[:path]
      tab.dup.merge(path:)
    end
  end
end
