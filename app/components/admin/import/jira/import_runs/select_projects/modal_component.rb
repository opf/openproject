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

module Admin::Import::Jira::ImportRuns::SelectProjects
  class ModalComponent < ApplicationComponent
    include ApplicationHelper
    include OpPrimer::ComponentHelpers
    include OpTurbo::Streamable

    MODAL_ID = "op-jira-select-projects-list-dialog"

    attr_reader :jira_import, :list_header_component, :list_component, :list_footer_component, :selected_count

    def initialize(jira_import:, list_header_component:, list_component:, list_footer_component:, selected_count:)
      super()
      @jira_import = jira_import
      @list_header_component = list_header_component
      @list_component = list_component
      @list_footer_component = list_footer_component
      @selected_count = selected_count
    end

    def toggle_url(project_id)
      toggle_admin_import_jira_run_select_projects_path(jira_id: jira_import.jira.id, run_id: jira_import.id, project_id:)
    end

    def filter_url
      filter_admin_import_jira_run_select_projects_path(jira_id: jira_import.jira.id, run_id: jira_import.id)
    end
  end
end
