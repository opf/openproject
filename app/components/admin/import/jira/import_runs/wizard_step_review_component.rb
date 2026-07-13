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
  class WizardStepReviewComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers
    include Admin::Import::Jira::ImportRunsHelper

    def imported_data
      [
        { label: projects_label(imported_projects.count), checked: true, url: imported_projects_url },
        { label: work_packages_label(imported_work_packages.count), checked: true, url: imported_work_packages_url }
      ].compact
    end

    def imported_projects
      @imported_projects ||= Import::JiraOpenProjectReference
        .where(jira_import: model, op_entity_class: "Project", uses_existing: false)
    end

    def imported_projects_url
      return nil if imported_projects.none?

      ids = imported_projects.pluck(:op_entity_id).map(&:to_s)
      if ids.length == 1
        helpers.project_path(id: ids[0])
      else
        helpers.projects_path(filters: [{ id: { operator: "=", values: ids } }].to_json)
      end
    end

    def imported_work_packages
      @imported_work_packages ||= Import::JiraOpenProjectReference
        .where(jira_import: model, op_entity_class: "WorkPackage", uses_existing: false)
    end

    def imported_work_packages_url
      return nil if imported_work_packages.none?

      wp_ids = imported_work_packages.pluck(:op_entity_id).map(&:to_s)
      if wp_ids.length == 1
        helpers.work_package_path(id: wp_ids[0])
      else
        project_ids = imported_projects.pluck(:op_entity_id).map(&:to_s)
        helpers.work_packages_path(query_props: { f: [{ n: "project", o: "=", v: project_ids }] }.to_json)
      end
    end
  end
end
