# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe "Workflows index" do
  include Toasts::Expectations

  let(:admin)  { create(:admin) }
  let!(:types) { create_list(:type, 3) }

  current_user { admin }

  before do
    visit url_for(controller: "/workflows", action: :index)
  end

  it "is accessible", :js, :selenium do
    expect(page).to be_axe_clean.within("#content")
  end

  it "allows quick-filtering by type name", :js do
    within "ul.Box-list" do
      expect(page).to have_css %{[data-filter--filter-list-target="searchItem"]}, count: types.count
    end

    some_type = types.sample
    fill_in "Filter by type name…", with: some_type.name

    within "ul.Box-list" do
      expect(page).to have_css %{[data-filter--filter-list-target="searchItem"]}, count: 1
      expect(page).to have_css("li", text: some_type.name)
    end
  end

  it "allows navigating to any Edit page" do
    expect(page).to have_heading("Workflows")

    some_type = types.sample
    within "ul.Box-list" do
      within "li", text: some_type.name do
        click_link some_type.name
      end
    end

    expect(page).to have_heading some_type.name
    expect(page).to have_current_path(edit_workflow_path(some_type))
  end

  it "allows navigating to any Copy page", :js do
    expect(page).to have_heading("Workflows")

    some_type = types.sample
    within "ul.Box-list" do
      within "li", text: some_type.name do
        find("button[aria-haspopup=true]").click
        click_link "Copy"
      end
    end

    expect(page).to have_heading "Copy workflow"
  end

  it "allows navigating to Workflow summary page" do
    within ".PageHeader-actions" do
      click_on "Summary"
    end

    expect(page).to have_heading "Summary"
    expect(page).to have_current_path(workflows_summary_path)
  end
end
