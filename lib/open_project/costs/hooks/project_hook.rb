#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

class OpenProject::Costs::Hooks::ProjectHook < Redmine::Hook::ViewListener
  # Renders up to two additional table headers to the membership setting
  #
  # Context:
  # * :project => Current project
  #
  def view_projects_settings_members_table_header(context = {})
    return unless context[:project] && context[:project].module_enabled?(:costs_module)

    result = ''
    user = User.current
    project = context[:project]

    result += content_tag(:th, User.human_attribute_name(:current_rate)) if user.allowed_to?(:view_hourly_rates, project)
    result += content_tag(:th, l(:caption_set_rate)) if user.allowed_to?(:edit_hourly_rates, project)

    result
  end

  # Renders an AJAX form to update the member's billing rate
  # Context:
  # * :project => Current project
  # * :member => Current Member record
  render_on :view_projects_settings_members_table_row, partial: 'hooks/costs/view_projects_settings_members_table_row'

  # Renders table headers to update the member's billing rate
  # Context:
  # * :project => Current project
  render_on :view_projects_settings_members_table_header, partial: 'hooks/costs/view_projects_settings_members_table_header'

  render_on :view_projects_settings_members_table_colgroup, partial: 'hooks/costs/view_projects_settings_members_table_colgroup'
  # TODO: implement  model_project_copy_before_save
end
