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

module WorkflowHelper
  def workflow_tabs(type)
    [
      { name: "always", label: I18n.t(:"admin.workflows.tabs.default_transitions") },
      { name: "author", label: I18n.t(:"admin.workflows.tabs.user_author") },
      { name: "assignee", label: I18n.t(:"admin.workflows.tabs.user_assignee") }
    ].map do |tab|
      tab.merge(
        partial: "workflows/form",
        path: edit_workflow_tab_path(type, tab[:name], params.permit(role_ids: [])),
        data: { "admin--workflow-checkbox-state-confirmation-trigger": "click",
                turbo_frame: "workflow-table",
                turbo_action: "advance" }
      )
    end
  end
end
