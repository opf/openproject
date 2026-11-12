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

module Admin::Import::Jira::ImportRuns
  class WizardStepReviewComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers
    include Admin::Import::Jira::ImportRunsHelper

    def imported_stats
      [
        stat_entry(:projects, imported_count("Project"), url: imported_projects_url),
        stat_entry(:work_packages, imported_count("WorkPackage"), url: imported_work_packages_url),
        stat_entry(:versions, imported_count("Version")),
        stat_entry(:sprints, imported_count("Sprint")),
        stat_entry(:users_and_groups, imported_count("User", "Group")),
        stat_entry(:other_settings, imported_count("Type", "Status", "IssuePriority", "WorkPackageCustomField"))
      ].compact
    end

    def stat_entry(key, value, url: nil)
      return if value.zero?

      scope = "admin.jira.run.wizard.sections.import_result.stats.#{key}"
      {
        label: I18n.t(:"#{scope}.label"),
        value:,
        subtitle: I18n.t(:"#{scope}.subtitle"),
        url:
      }
    end

    private

    def imported_count(*op_entity_classes)
      op_entity_classes.sum { |op_entity_class| imported_counts.fetch(op_entity_class, 0) }
    end

    def imported_counts
      @imported_counts ||= imported_references.group(:op_entity_class).count
    end

    def imported_references
      Import::JiraOpenProjectReference.where(jira_import: model, uses_existing: false)
    end

    def imported_ids(op_entity_class)
      imported_references.where(op_entity_class:).pluck(:op_entity_id).map(&:to_s)
    end

    def imported_project_ids
      @imported_project_ids ||= imported_ids("Project")
    end

    def imported_work_package_ids
      @imported_work_package_ids ||= imported_ids("WorkPackage")
    end

    def imported_projects_url
      return nil if imported_project_ids.empty?

      if imported_project_ids.one?
        helpers.project_path(id: imported_project_ids.sole)
      else
        helpers.projects_path(filters: [{ id: { operator: "=", values: imported_project_ids } }].to_json)
      end
    end

    def imported_work_packages_url
      return nil if imported_work_package_ids.empty?

      if imported_work_package_ids.one?
        helpers.work_package_path(id: imported_work_package_ids.sole)
      else
        helpers.work_packages_path(query_props: { f: [{ n: "project", o: "=", v: imported_project_ids }] }.to_json)
      end
    end
  end
end
