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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module WorkspaceHelper
  WORKSPACE_ICON_MAPPING = {
    project: :project,
    portfolio: :briefcase,
    program: :versions
  }.with_indifferent_access.freeze

  def new_workspace_title(workspace)
    return unless Project.workspace_types.key?(workspace.workspace_type)

    I18n.t(:"label_#{workspace.workspace_type}_new")
  end

  def workspace_icon(type) = WORKSPACE_ICON_MAPPING[type]

  # Returns a path to which the user should be redirected when cancelling the creation process of
  # a workspace item
  def workspace_creation_cancel_href(workspace, parent = nil)
    if parent.present?
      project_overview_path(parent.id)
    elsif workspace.portfolio?
      portfolios_path
    else
      projects_path
    end
  end
end
