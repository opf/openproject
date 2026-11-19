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

RSpec.describe "Admin members filtering", :js do
  current_user { create(:admin) }

  shared_let(:project_one) { create(:project, name: "Mercury") }
  shared_let(:project_two) { create(:project, name: "Venus") }
  shared_let(:reviewer) { create(:project_role, name: "Reviewer") }
  shared_let(:approver) { create(:project_role, name: "Approver") }

  shared_let(:alice) do
    create(:user, firstname: "Alice", lastname: "Reviewer", member_with_roles: { project_one => [reviewer] })
  end
  shared_let(:bob) do
    create(:user, firstname: "Bob", lastname: "Approver", member_with_roles: { project_one => [approver] })
  end
  shared_let(:carol) do
    create(:user, firstname: "Carol", lastname: "Reviewer", member_with_roles: { project_two => [reviewer] })
  end

  def quick_filter_by(filter_key, label)
    within("[data-quick-filter--select-panel-filter-key-value='#{filter_key}']") do
      find_test_selector("quick-filter-select-panel-button").click
      find("[role='option']", text: label).click
      click_link_or_button I18n.t(:button_apply)
    end
  end

  # Regression test: picking a second quick filter used to reset the first one instead of
  # combining with it, because the project quick filter wasn't forwarded to the
  # filter--filters-form Stimulus controller.
  it "combines a project and a role quick filter instead of the second resetting the first (#op-20315)" do
    visit admin_members_path

    expect(page).to have_text("Alice Reviewer")
    expect(page).to have_text("Bob Approver")
    expect(page).to have_text("Carol Reviewer")

    quick_filter_by(:project_id, "Mercury")

    expect(page).to have_text("Alice Reviewer")
    expect(page).to have_text("Bob Approver")
    expect(page).to have_no_text("Carol Reviewer")

    quick_filter_by(:role_id, "Reviewer")

    expect(page).to have_text("Alice Reviewer")
    expect(page).to have_no_text("Bob Approver")
    expect(page).to have_no_text("Carol Reviewer")
  end
end
