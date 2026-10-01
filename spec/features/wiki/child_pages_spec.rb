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

RSpec.describe "wiki child pages", :js, :selenium do
  let(:project) { create(:project, :with_internal_wiki).reload }
  let(:user) { create(:user, member_with_roles: { project => role }) }
  let(:role) { create(:project_role, permissions: %i[view_wiki_pages edit_wiki_pages]) }
  let(:parent_page) { create(:wiki_page, wiki: project.wiki) }
  let(:child_page_name) { 'The child page !@#{$%^&*()_},./<>?;\':' }

  before { login_as user }

  it "adding a child page" do
    visit project_wiki_path(project, parent_page.title)

    click_on "Wiki page"

    SeleniumHubWaiter.wait
    fill_in "page_title", with: child_page_name

    find(".ck-content").set("The child page's content")

    click_button "Create"

    # hierarchy displayed in the breadcrumb
    within('[data-test-selector="wiki-page-header-breadcrumbs"]') do
      expect(page).to have_text(parent_page.title.to_s)
    end

    # hierarchy displayed in the sidebar
    within_test_selector("wiki-sidemenu-tree") do
      expect(page).to have_link(parent_page.title)
      expect(page).to have_link(child_page_name)
    end

    # on toc page
    visit index_project_wiki_index_path(project)

    expect(page).to have_text(child_page_name)
  end
end
