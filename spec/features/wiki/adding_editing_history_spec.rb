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

RSpec.describe "wiki pages", :js, with_settings: { journal_aggregation_time_minutes: 0 } do
  let(:project) do
    create(:project, enabled_module_names: [:news])
  end
  let(:user) do
    create(:user, member_with_roles: { project => role })
  end
  let(:other_user) do
    create(:user, member_with_roles: { project => role })
  end
  let(:role) do
    create(:project_role,
           permissions: %i[view_wiki_pages
                           edit_wiki_pages
                           view_wiki_edits
                           select_project_modules
                           edit_project])
  end
  let(:content_first_version) do
    "The new content, first version"
  end
  let(:content_second_version) do
    "The new content, second version"
  end
  let(:content_third_version) do
    "The new content, third version"
  end
  let(:other_user_comment) do
    "Other users`s comment"
  end

  before do
    login_as user
  end

  it "adding, editing and history" do
    visit project_settings_modules_path(project)

    expect(page).to have_no_css(".menu-sidebar .main-item-wrapper", text: "Wiki")

    within "#content" do
      check "Wiki"

      click_button "Save"
    end

    expect(page).to have_css(".wiki-menu--main-item", text: "Wiki", visible: :all)

    # creating by accessing the page
    visit project_wiki_path(project, "new page")

    find(".ck-content").base.send_keys(content_first_version)
    click_button "Save"

    expect(page).to have_css(".title-container", text: "New page")
    expect(page).to have_css(".wiki-content", text: content_first_version)

    within ".toolbar-items" do
      SeleniumHubWaiter.wait
      click_on "Edit"
    end

    find(".ck-content").set(content_second_version)

    SeleniumHubWaiter.wait
    click_button "Save"
    expect(page).to have_css(".wiki-content", text: content_second_version)

    within ".toolbar-items" do
      SeleniumHubWaiter.wait
      click_on "More"
      click_on "History"
    end

    SeleniumHubWaiter.wait
    click_on "View differences"

    within ".text-diff" do
      expect(page).to have_css("ins.diffmod", text: "second")
      expect(page).to have_css("del.diffmod", text: "first")
    end

    SeleniumHubWaiter.wait
    # Go back to history
    find(".button", text: "History").click

    # Click on first version
    # to determine text (Regression test #31531)
    SeleniumHubWaiter.wait
    find("td.id a", text: 1).click

    expect(page).to have_css(".wiki-version--details", text: "Version 1/2")
    expect(page).to have_css(".wiki-content", text: content_first_version)

    SeleniumHubWaiter.wait
    find(".button", text: "Next").click

    expect(page).to have_css(".wiki-version--details", text: "Version 2/2")
    expect(page).to have_css(".wiki-content", text: content_second_version)

    login_as other_user

    visit project_wiki_path(project, "new page")

    within ".toolbar-items" do
      SeleniumHubWaiter.wait
      click_on "Edit"
    end

    find(".ck-content").set(content_third_version)

    fill_in "Comment", with: other_user_comment

    SeleniumHubWaiter.wait
    click_button "Save"

    within ".toolbar-items" do
      SeleniumHubWaiter.wait
      click_on "More"
      click_on "History"
    end

    expect(page).to have_css("tr.wiki-page-version:last-of-type .author", text: other_user.name)
    expect(page).to have_css("tr.wiki-page-version:last-of-type .comments", text: other_user_comment)
  end
end
