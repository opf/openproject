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
  # The transition matrix editor: the tab and role pickers, the matrix itself, and the
  # dirty-state machinery that warns before navigating away from unsaved changes.
  #
  # Renders no form of its own and no save button. Whoever embeds the editor wraps it in
  # a form and provides the control that submits it — the workflow tab has a pinned Save
  # bar, the creation wizard has Continue in its footer — so the editor stays identical
  # in both and needs nothing injected.
  class MatrixEditorComponent < ApplicationComponent
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    # The dirty-state controller's root. Other controllers reach it as a Stimulus outlet.
    STATE_ID = "workflow_matrix"

    def initialize(context:)
      super
      @context = context
    end

    private

    attr_reader :context

    delegate :type, :tab, :roles, :eligible_roles, :statuses, :readonly?, to: :context

    def state_id = STATE_ID

    def state_data
      {
        controller: "admin--workflow-checkbox-state",
        "admin--workflow-checkbox-state-has-status-changes-value": context.status_changes?
      }
    end

    def transition_tabs = @transition_tabs ||= helpers.workflow_tabs(type)

    def current_transition_tab = transition_tabs.find { it[:name] == tab }

    def matrix_table
      MatrixTableComponent.new(
        tab:,
        statuses:,
        workflows: context.workflows,
        roles:,
        added_status_ids: context.added_status_ids,
        readonly: readonly?
      )
    end

    def data_attributes
      {
        controller: "admin--workflow-role-select",
        "admin--workflow-role-select-base-url-value": helpers.type_workflow_matrix_path(type, tab:),
        "admin--workflow-role-select-current-role-ids-value": roles.map(&:id),
        "admin--workflow-role-select-admin--workflow-checkbox-state-outlet": "##{STATE_ID}"
      }
    end
  end
end
