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

RSpec.describe "Wiki page", :js do
  let(:project) { create(:project, enabled_module_names: %w[wiki]) }
  let(:user) do
    create(:user, member_with_permissions: { project => %i[view_wiki_pages rename_wiki_pages] })
  end
  let!(:wiki_page) do
    create(:wiki_page, wiki: project.wiki, title: initial_name)
  end
  let(:initial_name) { "Initial name" }
  let(:rename_name) { "Rename name" }

  before do
    login_as(user)
  end

  it "allows renaming" do
    visit project_wiki_path(project, wiki_page)

    SeleniumHubWaiter.wait
    click_link "More"
    click_link "Rename"

    SeleniumHubWaiter.wait
    fill_in "Title", with: rename_name

    click_button "Rename"

    expect(page)
      .to have_content(rename_name)

    # One can still use the former name to find the wiki page
    visit project_wiki_path(project, initial_name)

    within("#content") do
      expect(page)
        .to have_content(rename_name)
    end

    # But the application uses the new name preferably
    click_link rename_name

    expect(page)
      .to have_current_path(project_wiki_path(project, "rename-name"))
  end
end
