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

RSpec.describe "Navigation keyboard shortcuts", :js do
  def settle
    wait_for_network_idle
    page.evaluate_async_script("requestAnimationFrame(() => requestAnimationFrame(arguments[0]))")
  end

  let(:project) do
    create(:project, :with_internal_wiki, enabled_module_names: %w[work_package_tracking news wiki activity calendar_view]).reload
  end
  let(:permissions) { %i[view_work_packages view_news view_wiki_pages view_calendar] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }

  before { login_as(user) }

  context "in a project" do
    before do
      create(:wiki_page, wiki: project.wiki, title: project.wiki.start_page, text: "# Start page heading")
      visit project_work_packages_path(project)
    end

    it "navigates to the project pages" do
      page.send_keys("g", "o")
      expect(page).to have_current_path(project_path(project))

      page.send_keys("g", "w", "p")
      expect(page).to have_current_path(project_work_packages_path(project))

      page.send_keys("g", "w", "i")
      expect(page).to have_heading("Start page heading")
      expect(page).to have_current_path(%r{\A/projects/#{project.identifier}/wiki\z})

      page.send_keys("g", "a")
      expect(page).to have_current_path(%r{\A#{project_activity_index_path(project)}})

      page.send_keys("g", "c")
      expect(page).to have_current_path(project_calendars_path(project))

      page.send_keys("g", "n")
      expect(page).to have_current_path(project_news_index_path(project))

      page.send_keys("g", "m")
      expect(page).to have_current_path(my_page_path)
    end
  end

  context "with the news module disabled" do
    let(:project) { create(:project, :with_internal_wiki, enabled_module_names: %w[work_package_tracking]).reload }

    it "stays on the page for g n" do
      visit project_work_packages_path(project)
      expect(page).to have_current_path(project_work_packages_path(project))

      page.send_keys("g", "n")
      settle
      expect(page).to have_current_path(project_work_packages_path(project))
    end
  end

  context "with a wiki whose start page does not exist yet" do
    before { visit project_path(project) }

    it "opens the wiki page index for g w i" do
      page.send_keys("g", "w", "i")
      expect(page).to have_text("The requested page does not (yet) exist.")
      expect(page).to have_current_path(%r{\A/projects/#{project.identifier}/wiki/index\z})
    end
  end

  context "on a wiki page other than the start page" do
    before do
      create(:wiki_page, wiki: project.wiki, title: project.wiki.start_page, text: "# Start page heading")
      other = create(:wiki_page, wiki: project.wiki, title: "Other page", text: "# Other page heading")
      visit project_wiki_path(project, other.slug)
    end

    it "opens the wiki start page for g w i" do
      expect(page).to have_heading("Other page heading")

      page.send_keys("g", "w", "i")

      expect(page).to have_heading("Start page heading")
      expect(page).to have_current_path(%r{\A/projects/#{project.identifier}/wiki\z})
    end
  end

  context "when the start page menu item was removed but another main item remains" do
    before do
      create(:wiki_page, wiki: project.wiki, title: project.wiki.start_page, text: "# Start page heading")
      project.wiki.wiki_menu_items.destroy_all
      MenuItems::WikiMenuItem.create!(navigatable_id: project.wiki.id, title: "Other page", name: "other-page")
      visit project_path(project)
    end

    it "still opens the wiki start page for g w i" do
      page.send_keys("g", "w", "i")
      expect(page).to have_heading("Start page heading")
      expect(page).to have_current_path(%r{\A/projects/#{project.identifier}/wiki\z})
    end
  end

  context "when another page's menu item carries the start page caption" do
    before do
      create(:wiki_page, wiki: project.wiki, title: project.wiki.start_page, text: "# Start page heading")
      create(:wiki_page, wiki: project.wiki, title: "Other page", text: "# Other page heading")
      project.wiki.wiki_menu_items.destroy_all
      MenuItems::WikiMenuItem.create!(navigatable_id: project.wiki.id, title: project.wiki.start_page, name: "other-page")
      visit project_path(project)
    end

    it "opens the wiki start page for g w i" do
      page.send_keys("g", "w", "i")

      expect(page).to have_heading("Start page heading")
      expect(page).to have_current_path(%r{\A/projects/#{project.identifier}/wiki\z})
    end
  end

  context "on the My page" do
    before { visit my_page_path }

    it "navigates to the global pages" do
      page.send_keys("g", "o")
      settle
      expect(page).to have_current_path(my_page_path)

      page.send_keys("g", "w", "p")
      expect(page).to have_current_path(work_packages_path)

      visit my_page_path
      page.send_keys("g", "a")
      expect(page).to have_current_path(%r{\A/activity})

      visit my_page_path
      page.send_keys("g", "n")
      expect(page).to have_current_path(news_index_path)

      visit my_page_path
      page.send_keys("g", "c")
      expect(page).to have_current_path(calendars_path)

      visit my_page_path
      page.send_keys("g", "w", "i")
      expect(page).to have_current_path(url_for(controller: "/wikis/wiki_pages", action: "index", only_path: true))
    end
  end

  context "with a Turbo visit from a project page to the My page" do
    it "uses the global fallbacks" do
      visit project_path(project)
      find(:button, accessible_name: "Global modules").click
      click_link "My page"
      expect(page).to have_current_path(my_page_path)

      page.send_keys("g", "w", "p")
      expect(page).to have_current_path(work_packages_path)
    end
  end
end
