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

require "spec_helper"

RSpec.describe "Switching to project from work package", :js do
  let(:user) { create(:admin) }

  let(:project) { create(:project) }
  let(:another_project) { create(:project, parent: project) }
  let(:work_package) { create(:work_package, project:) }
  let(:work_package_from_another_project) { create(:work_package, project: another_project) }

  let(:wp_table) { Pages::WorkPackagesTable.new }
  let(:wp_project_table) { Pages::WorkPackagesTable.new(project) }
  let(:wp_page) { Pages::FullWorkPackage.new(work_package, project) }

  before do
    login_as(user)
    work_package
    work_package_from_another_project
  end

  it "does switch to the project context when being on the global WP table" do
    wp_table.visit!
    wp_table.expect_work_package_listed work_package
    wp_table.expect_work_package_listed work_package_from_another_project

    # Open WP in global selection
    wp_table.open_full_screen_by_link work_package

    # We are already in the project context and thus there is no project info box
    expect(page).to have_no_css(".attributes-group.-project-context")
    wp_page.expect_current_path
  end

  it "allows to switch to the project the work package belongs to" do
    wp_project_table.visit!

    # expect all WP to be visible
    wp_project_table.expect_work_package_listed work_package
    wp_project_table.expect_work_package_listed work_package_from_another_project

    wp_project_table.open_full_screen_by_link work_package_from_another_project

    # Follow link to project
    expect(page).to have_css(".attributes-group.-project-context")
    link = find(".attributes-group.-project-context .project-context--switch-link")
    expect(link[:href]).to include(project_path(another_project.id))

    link.click
    wait_for_network_idle
    expect(page).to have_current_path project_path(another_project.id)
  end
end
