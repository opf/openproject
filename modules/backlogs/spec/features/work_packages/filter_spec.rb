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

RSpec.describe "Filter work packages by backlog filters", :js do
  shared_let(:story_type) { create(:type_feature) }
  shared_let(:task_type) { create(:type_task) }
  shared_let(:project) do
    create(:project, types: [story_type, task_type], enabled_module_names: %w(work_package_tracking backlogs))
  end
  shared_let(:work_package_with_story_type) do
    create(:work_package,
           type: story_type,
           project:)
  end
  shared_let(:work_package_with_task_type) do
    create(:work_package,
           type: task_type,
           parent: work_package_with_story_type,
           project:)
  end
  shared_let(:own_sprint) { create(:sprint, project:) }
  shared_let(:shared_sprint) { create(:sprint, project: create(:project)) }
  shared_let(:work_package_in_own_sprint) { create(:work_package, type: task_type, project:, sprint: own_sprint) }
  shared_let(:work_package_in_shared_sprint) { create(:work_package, type: task_type, project:, sprint: shared_sprint) }

  let(:user) do
    create(:user,
           member_with_permissions: {
             project => permissions,
             shared_sprint.project => %i[show_board_views view_sprints]
           })
  end
  let(:permissions) { %i(view_work_packages save_queries show_board_views view_sprints) }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:filters) { Components::WorkPackages::Filters.new }

  before do
    login_as(user)

    wp_table.visit!
  end

  context "on the sprint" do
    shared_examples_for "filtering on sprints" do
      it "allows filtering by sprint" do
        filters.open

        filters.add_filter_by("Sprint", "is (OR)", own_sprint.name)

        wp_table.ensure_work_package_not_listed! work_package_in_shared_sprint,
                                                 work_package_with_story_type,
                                                 work_package_with_task_type
        wp_table.expect_work_package_listed work_package_in_own_sprint

        filters.clear_filter_value "sprint"
        filters.set_filter("Sprint", "is (OR)", shared_sprint.name)

        wp_table.ensure_work_package_not_listed! work_package_in_own_sprint,
                                                 work_package_with_story_type,
                                                 work_package_with_task_type
        wp_table.expect_work_package_listed work_package_in_shared_sprint

        filters.set_operator "Sprint", "is not"

        wp_table.ensure_work_package_not_listed! work_package_in_shared_sprint

        wp_table.expect_work_package_listed work_package_in_own_sprint,
                                            work_package_with_story_type,
                                            work_package_with_task_type

        filters.set_operator "Sprint", "is empty"

        wp_table.ensure_work_package_not_listed! work_package_in_shared_sprint,
                                                 work_package_in_own_sprint

        wp_table.expect_work_package_listed work_package_with_story_type,
                                            work_package_with_task_type

        filters.set_operator "Sprint", "is not empty"

        wp_table.ensure_work_package_not_listed! work_package_with_story_type,
                                                 work_package_with_task_type

        wp_table.expect_work_package_listed work_package_in_shared_sprint,
                                            work_package_in_own_sprint
      end
    end

    context "when filtering inside a project" do
      include_examples "filtering on sprints"
    end

    context "when filtering globally" do
      let(:wp_table) { Pages::WorkPackagesTable.new }

      include_examples "filtering on sprints"
    end
  end
end
