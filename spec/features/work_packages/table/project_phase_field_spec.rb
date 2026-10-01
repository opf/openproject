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

require "spec_helper"

RSpec.describe "Project phase field in the work package table", :js do
  let(:phase_definition) { create(:project_phase_definition, position: 2) }
  let(:project_phase) { create(:project_phase, definition: phase_definition) }
  let(:project_phase_from_other_project) { create(:project_phase, definition: phase_definition) }
  let(:other_project_phase) { create(:project_phase, definition: create(:project_phase_definition, position: 1)) }
  let(:project) { create(:project_with_types, phases: [project_phase, other_project_phase]) }
  let(:another_project) { create(:project_with_types, phases: [project_phase_from_other_project]) }
  let(:all_permissions) do
    %i[
      view_work_packages
      view_work_package_watchers
      edit_work_packages
      add_work_package_watchers
      delete_work_package_watchers
      manage_work_package_relations
      add_work_package_comments
      add_work_packages
      view_time_entries
      view_changesets
      view_file_links
      manage_file_links
      delete_work_packages
      view_project_phases
    ]
  end
  let(:work_package) do
    create(:work_package,
           project:,
           project_phase_definition: phase_definition,
           subject: "first wp",
           author: current_user)
  end
  let!(:other_wp) do
    create(:work_package,
           project:,
           project_phase_definition: other_project_phase.definition,
           subject: "other wp",
           author: current_user)
  end
  let!(:wp_without_phase) do
    create(:work_package,
           project:,
           subject: "wp without phase",
           author: current_user)
  end
  let!(:wp_from_another_project) do
    create(:work_package,
           project: another_project,
           subject: "wp from another project",
           author: current_user)
  end
  let!(:wp_with_phase_from_another_project) do
    create(:work_package,
           project: another_project,
           project_phase_definition: project_phase_from_other_project.definition,
           subject: "wp with phase from another project",
           author: current_user)
  end
  let!(:wp_table) { Pages::WorkPackagesTable.new(work_package.project) }
  let(:sort_criteria) { nil }
  let(:group_by) { nil }
  let(:user) do
    create(:user,
           member_with_permissions: {
             project => project_permissions,
             another_project => another_project_permissions
           })
  end
  let(:project_permissions) { all_permissions }
  let(:another_project_permissions) { all_permissions }
  let!(:query) do
    build(:public_query, user: current_user, project: work_package.project)
  end
  let(:query_columns) { %w(subject project_phase) }
  let(:query_filters) { nil }

  current_user { user }

  before do
    query.column_names  = query_columns
    query.sort_criteria = sort_criteria if sort_criteria
    query.group_by      = group_by if group_by
    query.filters.clear

    if query_filters.present?
      query_filters.each do |filter|
        query.add_filter(filter[:name], filter[:operator], filter[:values])
      end
    end

    query.show_hierarchies = false
    query.save!

    wp_table.visit_query query

    wait_for_network_idle
  end

  context "with the phase being active" do
    it "shows the project phase column with the correct phase for the work package" do
      wp_table.expect_work_package_with_attributes(work_package, { projectPhase: project_phase.name })
      wp_table.expect_work_package_with_attributes(other_wp, { projectPhase: other_project_phase.name })
      wp_table.expect_work_package_with_attributes(wp_without_phase, { projectPhase: "-" })
    end

    describe "filtering" do
      let(:query_filters) do
        [{ name: "project_phase_definition_id", operator:, values: }]
      end

      context "when filtering to include a phase" do
        let(:operator) { "=" }
        let(:values) { [phase_definition.id.to_s] }

        it "only shows work packages with this phase" do
          wp_table.expect_work_package_listed(work_package)
          wp_table.ensure_work_package_not_listed!(other_wp, wp_without_phase)
        end
      end

      context "when filtering to include multiple phases" do
        let(:operator) { "=" }
        let(:values) { [phase_definition.id.to_s, other_project_phase.definition.id.to_s] }

        it "only shows work packages with these phases" do
          wp_table.expect_work_package_listed(work_package, other_wp)
          wp_table.ensure_work_package_not_listed!(wp_without_phase)
        end
      end

      context "when filtering to exclude a phase" do
        let(:operator) { "!" }
        let(:values) { [other_project_phase.definition.id.to_s] }

        it "shows work packages with other phases or without a phase" do
          wp_table.expect_work_package_listed(wp_without_phase, work_package)
          wp_table.ensure_work_package_not_listed!(other_wp)
        end
      end

      context "when filtering to have a phase" do
        let(:operator) { "*" }
        let(:values) { nil }

        it "shows work packages with a phase" do
          wp_table.expect_work_package_listed(work_package, other_wp)
          wp_table.ensure_work_package_not_listed!(wp_without_phase)
        end
      end

      context "when filtering to not have a phase" do
        let(:operator) { "!*" }
        let(:values) { nil }

        it "shows work packages without a phase" do
          wp_table.expect_work_package_listed(wp_without_phase)
          wp_table.ensure_work_package_not_listed!(work_package, other_wp)
        end
      end
    end

    context "when sorting by project phase ASC" do
      let(:sort_criteria) { [%w[project_phase asc]] }

      it "sorts ASC by phase position" do
        wp_table.expect_work_package_order(wp_without_phase, other_wp, work_package)
      end
    end

    context "when sorting by project phase DESC" do
      let(:sort_criteria) { [%w[project_phase desc]] }

      it "sorts DESC by phase position" do
        wp_table.expect_work_package_order(work_package, other_wp, wp_without_phase)
      end
    end

    context "when editing the value of a project phase cell" do
      it "changes the value" do
        wp_table.update_work_package_attributes(wp_without_phase, projectPhase: phase_definition)
        wp_table.expect_work_package_with_attributes(wp_without_phase, { projectPhase: project_phase.name })
      end
    end

    context "when grouping by project phase" do
      let(:group_by) { :project_phase }

      it "groups by project phase" do
        wp_table.expect_groups({
                                 project_phase.name => 1,
                                 other_project_phase.name => 1,
                                 "-" => 1
                               })
      end

      it "includes the group icon in the group row header" do
        within("#wp-table-rowgroup-1") do
          expect(page).to have_test_selector("project-phase-icon phase-definition-#{other_project_phase.definition_id}")
        end

        within("#wp-table-rowgroup-2") do
          expect(page).to have_test_selector("project-phase-icon phase-definition-#{project_phase.definition_id}")
        end
      end
    end
  end

  context "with one phase being inactive" do
    let(:project_phase) { create(:project_phase, definition: phase_definition, active: false) }

    it "does not show the inactive phase" do
      wp_table.expect_work_package_with_attributes(other_wp, { projectPhase: other_project_phase.name })
      wp_table.expect_work_package_with_attributes(work_package, { projectPhase: "-" })
      wp_table.expect_work_package_with_attributes(wp_without_phase, { projectPhase: "-" })
    end

    context "when sorting by project phase ASC" do
      let(:sort_criteria) { [%w[project_phase asc]] }

      it "sorts work packages with an inactive project phase like work packages without a project phase" do
        wp_table.expect_work_package_order(work_package, wp_without_phase, other_wp)
      end
    end

    context "when grouping" do
      let(:group_by) { :project_phase }

      it "groups work packages with an inactive project phase like work packages without a project phase" do
        wp_table.expect_groups({
                                 other_project_phase.name => 1,
                                 "-" => 2
                               })
      end
    end

    describe "filtering" do
      let(:query_filters) do
        [{ name: "project_phase_definition_id", operator:, values: }]
      end
      let(:values) { [phase_definition.id.to_s, other_project_phase.definition.id.to_s] }

      context "when filtering to include multiple phases" do
        let(:operator) { "=" }

        it "does not consider inactive phases, even when you filter for them" do
          wp_table.expect_work_package_listed(other_wp)
          wp_table.ensure_work_package_not_listed!(wp_without_phase, work_package)
        end
      end

      context "when filtering to exclude phases" do
        let(:operator) { "!" }

        it "only excludes active phases, inactive phases are treated like they are not there" do
          # `work_package` is listed since its phase is inactive. The exclusion does not apply.
          wp_table.expect_work_package_listed(wp_without_phase, work_package)

          # successfully exclude the other work package:
          wp_table.ensure_work_package_not_listed!(other_wp)
        end
      end

      context "when filtering to have a phase" do
        let(:operator) { "*" }

        it "considers inactive phases" do
          wp_table.expect_work_package_listed(other_wp)
          wp_table.ensure_work_package_not_listed!(wp_without_phase, work_package)
        end
      end

      context "when filtering to not have a phase" do
        let(:operator) { "!*" }

        it "considers inactive phases" do
          wp_table.expect_work_package_listed(wp_without_phase, work_package)
          wp_table.ensure_work_package_not_listed!(other_wp)
        end
      end
    end
  end

  context "when viewing multiple projects" do
    let!(:query) { build(:global_query, user: current_user) }

    context "when a phase is active in one project, but inactive in another" do
      let(:project_phase_from_other_project) { create(:project_phase, active: false, definition: phase_definition) }

      it "shows the inactive phase as if it was not set" do
        wp_table.expect_work_package_with_attributes(other_wp, { projectPhase: other_project_phase.name })
        wp_table.expect_work_package_with_attributes(work_package, { projectPhase: phase_definition.name })

        # Has no phase at all:
        wp_table.expect_work_package_with_attributes(wp_from_another_project, { projectPhase: "" })
        wp_table.expect_work_package_with_attributes(wp_without_phase, { projectPhase: "-" })

        # Has an inactive phase:
        wp_table.expect_work_package_with_attributes(wp_with_phase_from_another_project, { projectPhase: "" })
      end

      context "when sorting by project phase ASC" do
        let(:sort_criteria) { [%w[project_phase asc]] }

        it "sorts work packages from projects with inactive phases like work packages without a project phase" do
          wp_table.expect_work_package_order(wp_with_phase_from_another_project, wp_from_another_project,
                                             wp_without_phase, other_wp, work_package)
        end
      end

      context "when grouping" do
        let(:group_by) { :project_phase }

        it "groups work packages with inactive phases like work packages without a project phase" do
          wp_table.expect_groups({
                                   other_project_phase.name => 1,
                                   project_phase.name => 1,
                                   "-" => 3
                                 })
        end
      end

      describe "filtering" do
        let(:query_filters) do
          [{ name: "project_phase_definition_id", operator:, values: }]
        end
        # mind that project_phase_from_other_project refers to the same phase_definition, but is set to inactive
        let(:values) { [phase_definition.id.to_s] }

        context "when filtering to include multiple phases" do
          let(:operator) { "=" }

          it "does not consider inactive phases, even when you filter for them" do
            wp_table.expect_work_package_listed(work_package)

            # has no matching phase, not listed:
            wp_table.ensure_work_package_not_listed!(wp_without_phase, wp_from_another_project, other_wp)
            # has the desired phase, but it's inactive, so not listed:
            wp_table.ensure_work_package_not_listed!(wp_with_phase_from_another_project)
          end
        end

        context "when filtering to exclude phases" do
          let(:operator) { "!" }

          it "only excludes active phases, inactive phases are treated like they are not there" do
            # The exclusion does not apply to the inactive phase:
            wp_table.expect_work_package_listed(wp_with_phase_from_another_project)
            # The exclusion does not apply if there is no phase at all:
            wp_table.expect_work_package_listed(wp_without_phase, wp_from_another_project, other_wp)

            # This phase is active and thus excluded:
            wp_table.ensure_work_package_not_listed!(work_package)
          end
        end

        context "when filtering to have a phase" do
          let(:operator) { "*" }

          it "treats inactive phases like they are not there" do
            wp_table.expect_work_package_listed(work_package, other_wp)
            wp_table.ensure_work_package_not_listed!(
              wp_without_phase, wp_from_another_project, wp_with_phase_from_another_project
            )
          end
        end

        context "when filtering to not have a phase" do
          let(:operator) { "!*" }

          it "treats inactive phases like they are not there" do
            wp_table.expect_work_package_listed(
              wp_without_phase, wp_from_another_project, wp_with_phase_from_another_project
            )
            wp_table.ensure_work_package_not_listed!(work_package, other_wp)
          end
        end
      end
    end
  end

  context "without the necessary permissions to view phases in some other projects" do
    let!(:query) { build(:global_query, user: current_user) }
    let(:another_project_permissions) { all_permissions - [:view_project_phases] }

    it "does not render project phases you don't have permission for" do
      # permission given, phase visible:
      wp_table.expect_work_package_with_attributes(work_package, { projectPhase: phase_definition.name })

      # permission missing, phase invisible:
      wp_table.expect_work_package_with_attributes(wp_from_another_project, { projectPhase: "" })
      wp_table.expect_work_package_with_attributes(wp_with_phase_from_another_project, { projectPhase: "" })
    end

    context "when sorting by project phase ASC" do
      let(:sort_criteria) { [%w[project_phase asc]] }

      it "sorts work packages from projects you don't have permission to like work packages without a project phase" do
        wp_table.expect_work_package_order(wp_with_phase_from_another_project, wp_from_another_project,
                                           wp_without_phase, other_wp, work_package)
      end
    end

    context "when grouping" do
      let(:group_by) { :project_phase }

      it "groups work packages from projects you don't have permission to like work packages without a project phase" do
        wp_table.expect_groups({
                                 other_project_phase.name => 1,
                                 project_phase.name => 1,
                                 "-" => 3
                               })
      end
    end

    describe "filtering" do
      let(:query_filters) do
        [{ name: "project_phase_definition_id", operator:, values: }]
      end
      let(:values) { [phase_definition.id.to_s, other_project_phase.definition.id.to_s] }
      let(:operator) { "=" }

      it "offers a phase filter" do
        expect(query.available_filters.map(&:name)).to include(:project_phase_definition_id)
      end

      context "when filtering to include multiple phases" do
        let(:operator) { "=" }

        it "does not consider unviewable phases, even when you filter for them" do
          wp_table.expect_work_package_listed(other_wp, work_package)

          wp_table.ensure_work_package_not_listed!(wp_with_phase_from_another_project, wp_without_phase)
        end
      end

      context "when filtering to exclude phases" do
        let(:operator) { "!" }

        it "only excludes active phases, inactive phases are treated like they are not there" do
          wp_table.expect_work_package_listed(
            wp_without_phase, wp_with_phase_from_another_project, wp_from_another_project
          )

          wp_table.ensure_work_package_not_listed!(other_wp, work_package)
        end
      end

      context "when filtering to have a phase" do
        let(:operator) { "*" }

        it "treats unviewable phases like they are not there" do
          wp_table.expect_work_package_listed(other_wp, work_package)

          wp_table.ensure_work_package_not_listed!(
            wp_without_phase, wp_with_phase_from_another_project, wp_from_another_project
          )
        end
      end

      context "when filtering to not have a phase" do
        let(:operator) { "!*" }

        it "treats unviewable phases like they are not there" do
          wp_table.expect_work_package_listed(
            wp_without_phase, wp_with_phase_from_another_project, wp_from_another_project
          )

          wp_table.ensure_work_package_not_listed!(other_wp, work_package)
        end
      end
    end
  end
end
