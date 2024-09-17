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

RSpec.describe "Wiki Activity", :js, :with_cuprite do
  let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_wiki_pages
                                                    edit_wiki_pages
                                                    view_wiki_edits] })
  end
  let(:project) { create(:project, enabled_module_names: %w[wiki activity]) }
  let(:wiki) { project.wiki }
  let(:editor) { Components::WysiwygEditor.new }

  before do
    login_as user
  end

  it "tracks the wiki's activities" do
    # create a wiki page
    visit project_wiki_path(project, "mypage")

    fill_in "page_title", with: "My page"

    editor.set_markdown("First content")

    click_button "Save"
    expect(page).to have_text("Successful creation")

    # We mock letting some time pass by altering the timestamps
    Journal.last.update_columns(created_at: Time.now - 5.days, updated_at: Time.now - 5.days)

    # alter the page
    click_link "Edit"

    editor.set_markdown("Second content")

    click_button "Save"
    expect(page).to have_text("Successful update")

    # After creating and altering the page, there
    # will be two activities to see
    visit project_activity_index_path(project)

    check "Wiki"

    click_button "Apply"

    expect(page)
      .to have_link("Wiki: My page")

    expect(page)
      .to have_link("Wiki: My page")

    within("li.op-activity-list--item", match: :first) do
      expect(page)
        .to have_css("li", text: "Text changed (Details)")
      expect(page)
        .to have_link("Details")
    end

    # Click on the second wiki activity item
    find(:xpath, "(//a[text()='Wiki: My page'])[1]").click

    expect(page)
      .to have_current_path(project_wiki_path(project.id, "my-page"))

    # disable the wiki module

    project.enabled_module_names = %w[activity]
    project.save!

    # Go to activity page again to see that
    # there is no more option to see wiki edits.

    visit project_activity_index_path(project)

    expect(page)
      .to have_no_content("Wiki edits")
  end
end
