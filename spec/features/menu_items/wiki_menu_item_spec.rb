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
require "features/page_objects/notification"
require "features/work_packages/shared_contexts"
require "features/work_packages/work_packages_page"

RSpec.describe "Wiki menu items" do
  let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_wiki_pages
                                                    manage_wiki_menu
                                                    delete_wiki_pages] })
  end
  let(:project) { create(:project, enabled_module_names: %w[wiki]) }
  let(:wiki) { project.wiki }
  let(:parent_menu) { wiki.wiki_menu_items.find_by(name: "wiki") }
  let(:wiki_page) { create(:wiki_page, wiki:) }
  let(:other_wiki_page) do
    create(:wiki_page, wiki:, title: "Other page").tap do |page|
      MenuItems::WikiMenuItem.create!(navigatable_id: page.wiki.id,
                                      title: page.title,
                                      name: page.slug)
    end
  end
  let(:another_wiki_page) do
    create(:wiki_page, wiki:)
  end

  before do
    allow(User).to receive(:current).and_return user
  end

  context "with identical names" do
    # Create two items with identical slugs (one with space, which is removed)
    let(:item1) do
      MenuItems::WikiMenuItem.new(navigatable_id: wiki.id,
                                  parent: parent_menu, title: "Item 1", name: "slug")
    end
    let(:item2) do
      MenuItems::WikiMenuItem.new(navigatable_id: wiki.id,
                                  parent: parent_menu, title: "Item 2", name: "slug ")
    end

    it "one is invalid and deleted during visit" do
      expect(wiki.wiki_menu_items.count).to eq(1)

      item1.save!
      item2.save!
      wiki.wiki_menu_items.reload
      expect(wiki.wiki_menu_items.count).to eq(3)

      visit project_wiki_path(project, project.wiki)

      wiki.wiki_menu_items.reload
      expect(wiki.wiki_menu_items.count).to eq(2)
      expect(wiki.wiki_menu_items.pluck(:name).sort).to eq(%w(slug wiki))
    end
  end

  it "allows managing the menu item of a wiki page", :js, :with_cuprite do
    other_wiki_page
    another_wiki_page

    visit project_wiki_path(project, wiki_page)

    # creating the menu item with the pages name for the menu item
    click_link "More"
    click_link "Configure menu item"

    choose "Show as menu item in project navigation"

    click_button "Save"

    expect(page)
      .to have_css(".main-menu--children-menu-header", text: wiki_page.title)

    find(".main-menu--arrow-left-to-project").click

    expect(page)
      .to have_css(".main-item-wrapper", text: wiki_page.title)

    # clicking the menu item leads to the page
    click_link wiki_page.title

    expect(page)
      .to have_current_path(project_wiki_path(project, wiki_page))

    # modifying the menu item to a different name and to be a subpage

    click_link "More"
    click_link "Configure menu item"

    fill_in "Name of menu item", with: "Custom page name"

    choose "Show as submenu item of"

    select other_wiki_page.slug, from: "parent_wiki_menu_item"

    click_button "Save"

    # the other page is now the main heading
    expect(page)
      .to have_css(".main-menu--children-menu-header", text: other_wiki_page.title)

    expect(page)
      .to have_css(".wiki-menu--sub-item", text: "Custom page name")

    click_link "Custom page name"

    expect(page)
      .to have_current_path(project_wiki_path(project, wiki_page))

    # the submenu item is not visible on top level
    find(".main-menu--arrow-left-to-project").click

    expect(page)
      .to have_no_css(".main-item-wrapper", text: "Custom page name")

    # deleting the page will remove the menu item
    visit project_wiki_path(project, wiki_page)

    click_link "More"
    accept_alert do
      click_link "Delete"
    end

    within "#menu-sidebar" do
      expect(page).to have_no_content("Custom page name")
    end

    # removing the menu item which is also the last wiki menu item
    # removing the default wiki menu item programmatically first
    MenuItems::WikiMenuItem.where(navigatable_id: project.wiki.id, name: "wiki").delete_all
    visit project_wiki_path(project, other_wiki_page)

    click_link "More"
    click_link "Configure menu item"

    choose "Do not show this wikipage in project navigation"

    click_button "Save"

    # Because it is the last wiki menu item, the user is prompted to select another menu item
    select another_wiki_page.title, from: "main-menu-item-select"

    click_button "Save"

    expect(page)
      .to have_no_css(".main-menu--children-menu-header", text: other_wiki_page.title)

    expect(page)
      .to have_css(".main-menu--children-menu-header", text: another_wiki_page.title)
  end
end
