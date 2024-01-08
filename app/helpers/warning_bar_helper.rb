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

module WarningBarHelper
  def render_pending_migrations_warning?
    current_user.admin? &&
      OpenProject::Configuration.show_pending_migrations_warning? &&
      OpenProject::Database.migrations_pending?
  end

  def render_host_and_protocol_mismatch?
    current_user.admin? &&
      OpenProject::Configuration.show_setting_mismatch_warning? &&
      (setting_protocol_mismatched? || setting_hostname_mismatched?)
  end

  def render_workflow_missing_warning?
    current_user.admin? &&
      EnterpriseToken.allows_to?(:work_package_sharing) &&
      no_workflow_for_wp_edit_role?
  end

  def setting_protocol_mismatched?
    request.ssl? != OpenProject::Configuration.https?
  end

  def setting_hostname_mismatched?
    Setting.host_name.gsub(/:\d+$/, '') != request.host
  end

  def no_workflow_for_wp_edit_role?
    workflow_exists = OpenProject::Cache.read('no_wp_share_editor_workflow')

    if workflow_exists.nil?
      workflow_exists = Workflow.exists?(role_id: Role.where(builtin: Role::BUILTIN_WORK_PACKAGE_EDITOR).select(:id))
      OpenProject::Cache.write('no_wp_share_editor_workflow', workflow_exists) if workflow_exists
    end

    !workflow_exists
  end

  ##
  # By default, never show a warning bar in the
  # test mode due to overshadowing other elements.
  def show_warning_bar?
    OpenProject::Configuration.show_warning_bars?
  end
end
