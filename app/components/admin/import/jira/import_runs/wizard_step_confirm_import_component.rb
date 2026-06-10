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

module Admin::Import::Jira::ImportRuns
  class WizardStepConfirmImportComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers
    include Admin::Import::Jira::ImportRunsHelper

    def import_selection
      [
        projects_label(selected_projects_count),
        issues_label(selected_issues_count),
        statuses_label(selected_statuses_count),
        types_label(selected_types_count)
      ]
        .compact
        .map { |label| { label:, checked: true } }
        .push({ label: I18n.t(:"admin.jira.run.wizard.sections.confirm_import.label_users_import_explanation") })
    end

    def selected_projects_count
      model.projects&.count || 0
    end

    def selected_issues_count
      model.selected["issues_count"]
    end

    def selected_types_count
      model.selected["issue_type_ids"]&.count
    end

    def selected_statuses_count
      model.selected["status_ids"]&.count
    end
  end
end
