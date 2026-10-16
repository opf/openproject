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

RSpec.describe "Work package table semantic ID navigation",
               :js,
               :with_cuprite,
               with_settings: { work_packages_identifier: "semantic" } do
  let(:user) { create(:admin) }
  let(:project) { create(:project, identifier: "NAVTEST") }
  let(:work_package) { create(:work_package, project:, subject: "Semantic nav test") }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }

  before do
    work_package
    login_as(user)
    wp_table.visit!
    wp_table.expect_work_package_listed(work_package)
  end

  it "navigates to the semantic ID URL when clicking the ID link" do
    semantic_id = work_package.reload.identifier

    # The ID column should show the semantic identifier
    expect(page).to have_link(semantic_id)

    # Click the semantic ID link in the table
    page.find("a", text: semantic_id).click

    # Should navigate to a URL containing the semantic identifier, not the numeric ID
    expect(page).to have_current_path(
      project_work_package_path(project, semantic_id, "activity")
    )
  end
end
