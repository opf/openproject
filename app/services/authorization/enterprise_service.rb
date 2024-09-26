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

class Authorization::EnterpriseService
  attr_accessor :token

  GUARDED_ACTIONS = %i[
    baseline_comparison
    board_view
    conditional_highlighting
    custom_actions
    date_alerts
    define_custom_style
    edit_attribute_groups
    gantt_pdf_export
    grid_widget_wp_graph
    ldap_groups
    one_drive_sharepoint_file_storage
    placeholder_users
    project_list_sharing
    readonly_work_packages
    sso_auth_providers
    team_planner_view
    two_factor_authentication
    virus_scanning
    work_package_query_relation_columns
    work_package_sharing
  ].freeze

  def initialize(token)
    self.token = token
  end

  # Return a true ServiceResult if the token contains this particular action.
  def call(action)
    allowed =
      if token.nil? || token.token_object.nil? || token.expired?
        false
      else
        process(action)
      end

    result(allowed)
  end

  private

  def process(action)
    # Every non-expired token
    GUARDED_ACTIONS.include?(action.to_sym)
  end

  def result(bool)
    ServiceResult.new(success: bool, result: bool)
  end
end
