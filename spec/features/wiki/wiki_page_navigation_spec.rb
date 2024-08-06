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

RSpec.describe "Wiki page navigation spec", :js do
  shared_let(:admin) { create(:admin) }
  current_user { admin }

  let(:project) { create(:project, enabled_module_names: %w[wiki]) }
  let!(:wiki_page_55) do
    create(:wiki_page,
           wiki: project.wiki,
           title: "Wiki Page No. 55")
  end
  let!(:wiki_pages) do
    create_list(:wiki_page, 30, wiki: project.wiki)
  end

  # Always use the same user for the wiki pages
  # that otherwise gets created
  before do
    FactoryBot.set_factory_default(:author, admin)
  end

  it "scrolls to the selected page on load (Regression #36937)" do
    visit project_wiki_path(project, wiki_page_55)

    expect(page).to have_css("div.wiki-content")

    expect(page).to have_css(".title-container h2", text: "Wiki Page No. 55")

    # Expect scrolled to menu node
    expect_element_in_view page.find(".tree-menu--item.-selected", text: "Wiki Page No. 55")

    # Expect permalink being correct (Regression #46351)
    permalink = page.all(".op-uc-link_permalink", visible: :all).first
    expect(permalink["href"]).to include "/projects/#{project.identifier}/wiki/wiki-page-no-55#wiki-page-no-55"
  end
end
