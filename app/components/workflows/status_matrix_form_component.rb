# frozen_string_literal: true

# -- copyright
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
# ++

module Workflows
  class StatusMatrixFormComponent < ApplicationComponent
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    FORM_ID = "workflow_form"

    def initialize(tab:, roles:, type:, available_roles:, statuses:, has_status_changes:,
                   workflows: {}, added_status_ids: [])
      super
      @tab = tab
      @roles = roles
      @type = type
      @available_roles = available_roles
      @statuses = statuses
      @has_status_changes = has_status_changes
      @workflows = workflows || {}
      @added_status_ids = added_status_ids || []
    end

    private

    def form_id = FORM_ID

    def read_only? = helpers.workflow_linked?(@type)

    def transition_tabs = @transition_tabs ||= helpers.workflow_tabs(@type)

    # The transition tab that is actually on screen. Not necessarily @tab, which is the
    # raw request param and is blank when the matrix is opened without one.
    def current_transition_tab = @current_transition_tab ||= helpers.selected_tab(transition_tabs)

    def matrix_table
      MatrixTableComponent.new(
        tab: current_transition_tab[:name],
        statuses: @statuses,
        workflows: @workflows.fetch(current_transition_tab[:name], []),
        roles: @roles,
        added_status_ids: @added_status_ids,
        readonly: read_only?
      )
    end

    def data_attributes
      {
        controller: "admin--workflow-role-select",
        "admin--workflow-role-select-base-url-value": helpers.edit_type_workflow_tab_path(@type, @tab),
        "admin--workflow-role-select-current-role-ids-value": @roles.map(&:id),
        "admin--workflow-role-select-admin--workflow-checkbox-state-outlet": "##{form_id}"
      }
    end
  end
end
