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

RSpec.describe "Backlog bucket displayed and selectable on work package table", :js do
  let(:enabled_module_names) { %i[backlogs work_package_tracking] }
  let(:bucket) { create(:backlog_bucket, project:, name: "Bucket") }
  let(:other_bucket) { create(:backlog_bucket, project:, name: "Other bucket") }
  let(:bucket_from_another_project) { create(:backlog_bucket, project: another_project, name: "Bucket from other project") }
  let(:project) { create(:project, name: "Project", enabled_module_names:) }
  let(:another_project) { create(:project, name: "Another project", enabled_module_names:) }
  let(:project_without_backlogs) { create(:project, name: "Project without backlogs") }
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
           backlog_bucket: bucket,
           subject: "first wp",
           author: current_user)
  end
  let!(:other_wp) do
    create(:work_package,
           project:,
           backlog_bucket: other_bucket,
           subject: "other wp",
           author: current_user)
  end
  let!(:wp_without_bucket) do
    create(:work_package,
           project:,
           subject: "wp without bucket",
           author: current_user)
  end
  let!(:wp_from_another_project) do
    create(:work_package,
           project: another_project,
           subject: "wp from another project",
           author: current_user)
  end
  let!(:wp_with_bucket_from_another_project) do
    create(:work_package,
           project: another_project,
           backlog_bucket: bucket_from_another_project,
           subject: "wp with bucket from another project",
           author: current_user)
  end
  let!(:wp_without_backlogs_module) do
    create(:work_package,
           project: project_without_backlogs,
           subject: "wp without backlogs module",
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
             project_without_backlogs => disabled_module_permissions
           })
  end
  let(:project_permissions) { all_permissions }
  let(:another_project_permissions) { all_permissions }
  let(:disabled_module_permissions) { all_permissions - %i[view_sprints] }
  let!(:query) do
    build(:public_query, user: current_user, project: work_package.project)
  end
  let(:query_columns) { %w(subject backlog_bucket) }

  current_user { user }

  def visit_page!
    query.column_names  = query_columns
    query.sort_criteria = sort_criteria if sort_criteria
    query.group_by      = group_by if group_by
    query.filters.clear
    query.show_hierarchies = false
    query.save!

    wp_table.visit_query query

    wait_for_network_idle
  end

  before do
    visit_page!
  end

  context "when viewing backlog buckets" do
    it "shows the backlog bucket column with the correct bucket for the work package" do
      wp_table.expect_work_package_with_attributes(work_package, { backlog_bucket: bucket.name })
      wp_table.expect_work_package_with_attributes(other_wp, { backlog_bucket: other_bucket.name })
      wp_table.expect_work_package_with_attributes(wp_without_bucket, { backlog_bucket: "-" })
    end

    context "when sorting by backlog bucket ASC" do
      let(:sort_criteria) { [%w[backlog_bucket asc]] }

      it "sorts ASC by bucket name" do
        wp_table.expect_work_package_order(work_package, other_wp, wp_without_bucket)
      end
    end

    context "when sorting by backlog bucket DESC" do
      let(:sort_criteria) { [%w[backlog_bucket desc]] }

      it "sorts DESC by bucket name" do
        wp_table.expect_work_package_order(wp_without_bucket, other_wp, work_package)
      end
    end

    context "when editing the value of a backlog bucket cell" do
      it "changes the value" do
        wp_table.update_work_package_attributes(wp_without_bucket, backlog_bucket: bucket)
        wp_table.expect_work_package_with_attributes(wp_without_bucket, { backlog_bucket: bucket.name })
      end
    end

    context "when grouping by backlog bucket" do
      let(:group_by) { :backlog_bucket }

      let!(:other_other_wp) do
        create(:work_package,
               project:,
               backlog_bucket: other_bucket,
               subject: "other other wp",
               author: current_user)
      end

      before do
        visit_page!
      end

      it "groups by backlog bucket" do
        wp_table.expect_groups({
                                 bucket.name => 1,
                                 other_bucket.name => 2,
                                 "-" => 1
                               })
      end

      context "when sorting by backlog bucket DESC" do
        let(:sort_criteria) { [%w[backlog_bucket desc]] }

        it "allows grouping and sorting at the same time" do
          wp_table.expect_groups({
                                   bucket.name => 1,
                                   other_bucket.name => 2,
                                   "-" => 1
                                 })

          wp_table.expect_work_package_order(wp_without_bucket, other_other_wp, other_wp, work_package)
        end
      end
    end

    context "with global query" do
      let!(:query) { build(:global_query, user: current_user) }

      context "when sorting by backlog bucket ASC" do
        let(:sort_criteria) { [%w[backlog_bucket asc]] }

        it "sorts by backlog bucket ASC" do
          wp_table.expect_work_package_order(work_package, wp_with_bucket_from_another_project, other_wp,
                                             wp_without_backlogs_module, wp_from_another_project, wp_without_bucket)
        end
      end
    end
  end

  context "when sorting by bucket and sprint at the same time" do
    let(:sort_criteria) { [%w[sprint asc], %w[backlog_bucket asc]] }

    let!(:sprint) { create(:sprint, project:) }

    before do
      wp_without_bucket.sprint = sprint
      wp_without_bucket.save!

      visit_page!
    end

    it "does not throw an error (regression)" do
      wp_table.expect_work_package_order(wp_without_bucket, work_package, other_wp)
    end
  end

  context "without the necessary permissions to view sprints in some other projects" do
    let!(:query) { build(:global_query, user: current_user) }
    let(:another_project_permissions) { all_permissions - [:view_sprints] }

    it "does not render buckets you don't have permission for" do
      # permission given, bucket visible:
      wp_table.expect_work_package_with_attributes(work_package, { backlog_bucket: bucket.name })

      # permission missing, bucket invisible:
      wp_table.expect_work_package_with_attributes(wp_from_another_project, { backlog_bucket: "" })
      wp_table.expect_work_package_with_attributes(wp_with_bucket_from_another_project, { backlog_bucket: "" })
    end

    context "when sorting by backlog bucket ASC" do
      let(:sort_criteria) { [%w[backlog_bucket asc]] }

      it "sorts work packages from projects you don't have permission to like work packages without a bucket" do
        wp_table.expect_work_package_order(work_package, other_wp, wp_without_backlogs_module,
                                           wp_with_bucket_from_another_project, wp_from_another_project,
                                           wp_without_bucket)
      end
    end

    context "when grouping" do
      let(:group_by) { :backlog_bucket }

      it "groups work packages from projects you don't have permission to like work packages without a bucket" do
        wp_table.expect_groups({
                                 bucket.name => 1,
                                 other_bucket.name => 1,
                                 "-" => 4
                               })
      end
    end
  end

  context "without being a member in a project at all" do
    let!(:query) { build(:global_query, user: current_user) }
    let!(:project_where_user_is_no_member) { create(:project) }
    let!(:bucket_that_user_cannot_see) { create(:backlog_bucket, project: project_where_user_is_no_member) }
    let!(:work_package_that_user_cannot_see) do
      create(:work_package, project: project_where_user_is_no_member, backlog_bucket: bucket_that_user_cannot_see)
    end

    context "when grouping" do
      let(:group_by) { :backlog_bucket }

      it "ignores work packages from projects you cannot see" do
        wp_table.ensure_work_package_not_listed!(work_package_that_user_cannot_see)
        wp_table.expect_groups({
                                 bucket.name => 1,
                                 other_bucket.name => 1,
                                 bucket_from_another_project.name => 1,
                                 "-" => 3 # There are 4 work packages here, but the user only sees 3
                               })
      end
    end
  end
end
