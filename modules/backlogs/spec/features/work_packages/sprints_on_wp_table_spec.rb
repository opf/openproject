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

RSpec.describe "Sprint displayed and selectable on work package table", :js do
  let(:enabled_module_names) { %i[backlogs work_package_tracking] }
  let(:start_date) { Date.new(2025, 10, 5) }
  let(:finish_date) { Date.new(2025, 10, 25) }
  let(:other_start_date) { start_date + 20.days }
  let(:other_finish_date) { finish_date + 20.days }
  let(:sprint) { create(:sprint, project:, name: "Sprint", start_date:, finish_date:) }
  let(:other_sprint_name) { "Other sprint" }
  let(:other_sprint) do
    create(:sprint,
           project:,
           name: other_sprint_name,
           start_date: other_start_date,
           finish_date: other_finish_date)
  end
  let(:sprint_from_other_project) { create(:sprint, project: another_project, name: "Sprint from other project") }
  let(:project) { create(:project, name: "Project", enabled_module_names:) }
  let(:project_sharing) do
    create(:project,
           name: "Global sharer project",
           sprint_sharing: "share_all_projects",
           enabled_module_names:)
  end
  let(:project_receiving) { create(:project, name: "Receiving project", sprint_sharing: "receive_shared", enabled_module_names:) }
  let(:another_project) { create(:project, name: "Another project", enabled_module_names:) }
  let(:all_permissions) do
    %i[
      view_work_packages
      edit_work_packages
      manage_work_package_relations
      add_work_packages
      delete_work_packages

      view_sprints
      manage_sprint_items
    ]
  end
  let(:work_package) do
    create(:work_package,
           project:,
           sprint:,
           subject: "first wp",
           author: current_user)
  end
  let!(:other_wp) do
    create(:work_package,
           project:,
           sprint: other_sprint,
           subject: "other wp",
           author: current_user)
  end
  let!(:wp_without_sprint) do
    create(:work_package,
           project:,
           subject: "wp without sprint",
           author: current_user)
  end
  let!(:wp_from_another_project) do
    create(:work_package,
           project: another_project,
           subject: "wp from another project",
           author: current_user)
  end
  let!(:wp_with_sprint_from_another_project) do
    create(:work_package,
           project: another_project,
           sprint: sprint_from_other_project,
           subject: "wp with sprint from another project",
           author: current_user)
  end
  let!(:wp_table) { Pages::WorkPackagesTable.new(work_package.project) }
  let(:sort_criteria) { nil }
  let(:group_by) { nil }
  let(:user) do
    create(:user,
           member_with_permissions: {
             project => project_permissions,
             another_project => another_project_permissions,
             project_receiving => shared_project_permissions,
             project_sharing => sharer_project_permissions
           })
  end
  let(:project_permissions) { all_permissions }
  let(:another_project_permissions) { all_permissions }
  let(:shared_project_permissions) { all_permissions }
  let(:sharer_project_permissions) { all_permissions }
  let!(:query) do
    build(:public_query, user: current_user, project: work_package.project)
  end
  let(:query_columns) { %w(subject sprint) }
  let(:query_filters) { nil }

  current_user { user }

  def visit_page!
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

  before do
    visit_page!
  end

  context "when viewing sprints" do
    it "shows the sprint column with the correct sprint for the work package" do
      wp_table.expect_work_package_with_attributes(work_package, { sprint: sprint.name })
      wp_table.expect_work_package_with_attributes(other_wp, { sprint: other_sprint.name })
      wp_table.expect_work_package_with_attributes(wp_without_sprint, { sprint: "-" })
    end

    describe "filtering" do
      let(:query_filters) do
        [{ name: "sprint_id", operator:, values: }]
      end

      context "when filtering to include a sprint" do
        let(:operator) { "=" }
        let(:values) { [sprint.id.to_s] }

        it "only shows work packages with this sprint" do
          wp_table.expect_work_package_listed(work_package)
          wp_table.ensure_work_package_not_listed!(other_wp, wp_without_sprint)
        end
      end

      context "when filtering to include multiple sprints" do
        let(:operator) { "=" }
        let(:values) { [sprint.id.to_s, other_sprint.id.to_s] }

        it "only shows work packages with these sprints" do
          wp_table.expect_work_package_listed(work_package, other_wp)
          wp_table.ensure_work_package_not_listed!(wp_without_sprint)
        end
      end

      context "when filtering to exclude a sprint" do
        let(:operator) { "!" }
        let(:values) { [other_sprint.id.to_s] }

        it "shows work packages with other sprints or without a sprint" do
          wp_table.expect_work_package_listed(wp_without_sprint, work_package)
          wp_table.ensure_work_package_not_listed!(other_wp)
        end
      end

      context "when filtering to have a sprint" do
        let(:operator) { "*" }
        let(:values) { nil }

        it "shows work packages with a sprint" do
          wp_table.expect_work_package_listed(work_package, other_wp)
          wp_table.ensure_work_package_not_listed!(wp_without_sprint)
        end
      end

      context "when filtering to not have a sprint" do
        let(:operator) { "!*" }
        let(:values) { nil }

        it "shows work packages without a sprint" do
          wp_table.expect_work_package_listed(wp_without_sprint)
          wp_table.ensure_work_package_not_listed!(work_package, other_wp)
        end
      end
    end

    context "when sorting by sprint ASC" do
      let(:sort_criteria) { [%w[sprint asc]] }

      it "sorts ASC by sprint name" do
        wp_table.expect_work_package_order(other_wp, work_package, wp_without_sprint)
      end

      context "when sorting via name and dates" do
        # Name is identical to the first sprint now, so the dates are used as second sorting criterion:
        let(:other_sprint_name) { sprint.name }

        it "sorts ASC by name and then start date and finish date" do
          wp_table.expect_work_package_order(work_package, other_wp, wp_without_sprint)
        end
      end
    end

    context "when sorting by sprint DESC" do
      let(:sort_criteria) { [%w[sprint desc]] }

      it "sorts DESC by sprint name" do
        wp_table.expect_work_package_order(wp_without_sprint, work_package, other_wp)
      end
    end

    context "when editing the value of a sprint cell" do
      it "changes the value" do
        wp_table.update_work_package_attributes(wp_without_sprint, sprint: sprint)
        wp_table.expect_work_package_with_attributes(wp_without_sprint, { sprint: sprint.name })
      end
    end

    context "when grouping by sprint" do
      let(:group_by) { :sprint }

      it "groups by sprint" do
        wp_table.expect_groups({
                                 sprint.name => 1,
                                 other_sprint.name => 1,
                                 "-" => 1
                               })
      end
    end
  end

  context "without the necessary permissions to view sprints in some other projects" do
    let!(:query) { build(:global_query, user: current_user) }
    let(:another_project_permissions) { all_permissions - [:view_sprints] }

    it "does not render sprints you don't have permission for" do
      # permission given, sprint visible:
      wp_table.expect_work_package_with_attributes(work_package, { sprint: sprint.name })

      # permission missing, sprint invisible:
      wp_table.expect_work_package_with_attributes(wp_from_another_project, { sprint: "" })
      wp_table.expect_work_package_with_attributes(wp_with_sprint_from_another_project, { sprint: "" })
    end

    context "when sorting by sprint ASC" do
      let(:sort_criteria) { [%w[sprint asc]] }

      it "sorts work packages from projects you don't have permission to like work packages without a sprint" do
        wp_table.expect_work_package_order(other_wp, work_package, wp_with_sprint_from_another_project,
                                           wp_from_another_project, wp_without_sprint)
      end
    end

    context "when grouping" do
      let(:group_by) { :sprint }

      it "groups work packages from projects you don't have permission to like work packages without a sprint" do
        wp_table.expect_groups({
                                 other_sprint.name => 1,
                                 sprint.name => 1,
                                 "-" => 3
                               })
      end
    end
  end

  context "without being a member in a project at all" do
    let!(:query) { build(:global_query, user: current_user) }
    let!(:project_where_user_is_no_member) { create(:project) }
    let!(:sprint_that_user_cannot_see) { create(:sprint, project: project_where_user_is_no_member) }
    let!(:work_package_that_user_cannot_see) do
      create(:work_package, project: project_where_user_is_no_member, sprint: sprint_that_user_cannot_see)
    end

    context "when grouping" do
      let(:group_by) { :sprint }

      it "ignores work packages from projects you cannot see" do
        wp_table.ensure_work_package_not_listed!(work_package_that_user_cannot_see)
        wp_table.expect_groups({
                                 other_sprint.name => 1,
                                 sprint.name => 1,
                                 sprint_from_other_project.name => 1,
                                 "-" => 2 # There are 3 work packages here, but the user only sees 2
                               })
      end
    end
  end

  context "when a sprint is shared" do
    let(:shared_sprint) { create(:sprint, project: project_sharing, name: "Shared sprint") }
    let!(:query) { build(:global_query, user: current_user) }
    let!(:wp_with_shared_sprint) do
      create(:work_package,
             project: project_sharing,
             sprint: shared_sprint,
             subject: "wp with shared sprint")
    end

    before do
      visit_page!
    end

    it "can be queried" do
      wp_table.expect_work_package_with_attributes(wp_with_shared_sprint, { sprint: shared_sprint.name })
    end

    context "when sorting by sprint ASC" do
      let(:sort_criteria) { [%w[sprint asc]] }

      it "can be sorted" do
        wp_table.expect_work_package_order(other_wp, wp_with_shared_sprint, work_package,
                                           wp_with_sprint_from_another_project,
                                           wp_from_another_project, wp_without_sprint)
      end
    end

    context "when the user lacks permission in the sharer project" do
      let(:sharer_project_permissions) { all_permissions - [:view_sprints] }

      it "hides the sprint" do
        wp_table.expect_work_package_with_attributes(wp_with_shared_sprint, { sprint: "" })
      end

      context "when sorting by sprint ASC" do
        let(:sort_criteria) { [%w[sprint asc]] }

        it "sorts work packages with the hidden sprint like work packages without a sprint" do
          wp_table.expect_work_package_with_attributes(wp_with_shared_sprint, { sprint: "" })
          wp_table.expect_work_package_order(other_wp, work_package, wp_with_sprint_from_another_project,
                                             wp_with_shared_sprint, wp_from_another_project, wp_without_sprint)
        end
      end

      context "when grouping" do
        let(:group_by) { :sprint }

        it "groups work packages with the hidden sprint together with no-sprint work packages" do
          wp_table.expect_groups({
                                   other_sprint.name => 1,
                                   sprint.name => 1,
                                   sprint_from_other_project.name => 1,
                                   "-" => 3
                                 })

          wp_table.expect_work_package_with_attributes(wp_with_shared_sprint, { sprint: "" })
        end
      end
    end

    context "when the user lacks permission in the receiving project" do
      let(:shared_project_permissions) { all_permissions - [:view_sprints] }

      it "still shows the sprint (permission check is on the sprint's source project, not the receiver)" do
        wp_table.expect_work_package_with_attributes(wp_with_shared_sprint, { sprint: shared_sprint.name })
      end

      context "when sorting by sprint ASC" do
        let(:sort_criteria) { [%w[sprint asc]] }

        it "sorts the shared sprint together with other visible sprints" do
          wp_table.expect_work_package_with_attributes(wp_with_shared_sprint, { sprint: shared_sprint.name })
          wp_table.expect_work_package_order(other_wp, wp_with_shared_sprint, work_package,
                                             wp_with_sprint_from_another_project,
                                             wp_from_another_project, wp_without_sprint)
        end
      end

      context "when grouping" do
        let(:group_by) { :sprint }

        it "groups the shared sprint with the other visible sprints" do
          wp_table.expect_groups({
                                   other_sprint.name => 1,
                                   shared_sprint.name => 1,
                                   sprint.name => 1,
                                   sprint_from_other_project.name => 1,
                                   "-" => 2
                                 })

          wp_table.expect_work_package_with_attributes(wp_with_shared_sprint, { sprint: shared_sprint.name })
        end
      end
    end
  end
end
