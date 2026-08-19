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

    def initialize(tab:, roles:, type:, available_roles:, statuses:, has_status_changes:)
      super
      @tab = tab
      @roles = roles
      @type = type
      @available_roles = available_roles
      @statuses = statuses
      @has_status_changes = has_status_changes
    end

    private

    def form_id = FORM_ID

    def data_attributes
      {
        controller: "admin--workflow-role-select",
        "admin--workflow-role-select-base-url-value": helpers.edit_workflow_tab_path(@type, @tab),
        "admin--workflow-role-select-current-role-ids-value": @roles.map(&:id),
        "admin--workflow-role-select-admin--workflow-checkbox-state-outlet": "##{form_id}"
      }
    end
  end
end
