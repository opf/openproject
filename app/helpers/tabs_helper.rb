#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module TabsHelper
  # Renders tabs and their content
  def render_tabs(tabs, form = nil)
    if tabs.any?
      selected_tab = tabs.detect { |t| t[:name] == params[:tab] } if params[:tab].present?
      render partial: 'common/tabs', locals: { f: form, tabs: tabs, selected_tab: selected_tab || tabs.first }
    else
      content_tag 'p', l(:label_no_data), class: 'nodata'
    end
  end

  # Render tabs from the ui/extensible tabs manager
  def render_extensible_tabs(key, params = {})
    tabs = ::OpenProject::Ui::ExtensibleTabs.enabled_tabs(key).map do |tab|
      path = tab[:path].respond_to?(:call) ? instance_exec(params, &tab[:path]) : tab[:path]
      tab.dup.merge path: path
    end
    render_tabs(tabs)
  end
end
