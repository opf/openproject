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

    delegate :variant, :tab, :roles, :eligible_roles, :statuses, :readonly?, to: :context

    def state_id = STATE_ID

    # TODO: Remove with type_variants feature flag
    def copy_button_label
      if OpenProject::FeatureDecisions.type_variants_active?
        I18n.t(:label_copy_workflow_from_role)
      else
        I18n.t(:button_copy)
      end
    end

    def state_data
      {
        controller: "admin--workflow-checkbox-state",
        "admin--workflow-checkbox-state-variant-id-value": variant.id,
        "admin--workflow-checkbox-state-has-status-changes-value": context.status_changes?,
        # for saving the workflow when switching tabs
        "admin--workflow-checkbox-state-save-url-value": helpers.type_workflow_matrix_path(**variant.path_args, tab:)
      }
    end

    def transition_tabs
      @transition_tabs ||= MatrixContext::TABS.map { transition_tab(it) }
    end

    def transition_tab(name)
      {
        name:,
        label: I18n.t(:"admin.workflows.tabs.#{name}"),
        description: I18n.t(:"admin.workflows.tabs.descriptions.#{name}"),
        path: helpers.type_workflow_matrix_path(**variant.path_args, tab: name, role_ids: roles.map(&:id)),
        data: {
          controller: "admin--workflow-tab-select",
          action: "click->admin--workflow-tab-select#select",
          "admin--workflow-tab-select-tab-value": name,
          "admin--workflow-tab-select-admin--workflow-checkbox-state-outlet": "##{STATE_ID}"
        }
      }
    end

    def current_transition_tab
      transition_tabs.find { it[:name] == tab }
    end

    def data_attributes
      {
        controller: "admin--workflow-role-select",
        "admin--workflow-role-select-base-url-value": helpers.type_workflow_matrix_path(**variant.path_args, tab:),
        "admin--workflow-role-select-current-role-ids-value": roles.map(&:id),
        "admin--workflow-role-select-admin--workflow-checkbox-state-outlet": "##{STATE_ID}"
      }
    end
  end
end
