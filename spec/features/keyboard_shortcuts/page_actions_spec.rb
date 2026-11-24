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

RSpec.describe "Page action keyboard shortcuts", :js do
  let(:project) do
    create(:project, :with_internal_wiki, enabled_module_names: %w[work_package_tracking news wiki]).reload
  end
  let(:permissions) do
    %i[view_work_packages add_work_packages view_wiki_pages edit_wiki_pages view_wiki_edits view_news manage_news]
  end
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }

  let(:top_menu) { Components::Projects::TopMenu.new }

  before { login_as(user) }

  describe "p" do
    before { visit project_path(project) }

    it "opens the project select" do
      page.send_keys("p")

      top_menu.expect_open
    end
  end

  describe "?" do
    before do
      allow(OpenProject::Static::Links).to receive(:url_for).and_call_original
      allow(OpenProject::Static::Links).to receive(:url_for).with(:shortcuts).and_return("/my/page")
      visit project_path(project)
    end

    it "opens the shortcuts help in one new window" do
      window = window_opened_by { page.send_keys([:shift, "?"]) }

      expect(page.windows.size).to eq(2)
      window.close
    end
  end

  describe "g e" do
    it "edits a wiki page" do
      wiki_page = create(:wiki_page, wiki: project.wiki)
      visit project_wiki_path(project, wiki_page.slug)

      page.send_keys("g", "e")

      expect(page).to have_current_path(%r{/wiki/[^/]+/edit\z})
    end

    it "edits from the wiki annotate page" do
      wiki_page = create(:wiki_page, wiki: project.wiki)
      visit url_for(controller: "/wiki", action: "annotate", project_id: project.identifier,
                    id: wiki_page.slug, version: 1, only_path: true)

      page.send_keys("g", "e")

      expect(page).to have_current_path(%r{/wiki/[^/]+/edit\z})
    end

    it "edits a news item" do
      news = create(:news, project:)
      visit project_news_path(project, news)

      page.send_keys("g", "e")

      expect(page).to have_current_path(edit_project_news_path(project, news))
    end

    context "as an admin on a user page" do
      let(:user) { create(:admin) }

      it "edits the user" do
        visit user_path(user)

        page.send_keys("g", "e")

        expect(page).to have_current_path(edit_user_path(user))
      end

      it "keeps access key 3 on the desktop Edit link and edits with g e at a narrow viewport" do
        visit user_path(user)
        expect(page).to have_element(:a, accesskey: "3", count: 1, visible: :all)
        expect(page).to have_element(:a, accesskey: "3", visible: :visible)

        page.current_window.resize_to(500, 900)
        expect(page).to have_element(:a, accesskey: "3", count: 1, visible: :all)

        page.send_keys("g", "e")
        expect(page).to have_current_path(edit_user_path(user))
      ensure
        page.current_window.resize_to(1920, 1080)
      end

      it "edits a placeholder user" do
        placeholder_user = create(:placeholder_user)
        visit placeholder_user_path(placeholder_user)

        page.send_keys("g", "e")

        expect(page).to have_current_path(edit_placeholder_user_path(placeholder_user))
      end
    end
  end

  describe "n w p" do
    it "opens the global form from the My page" do
      visit my_page_path

      page.send_keys("n", "w", "p")

      expect(page).to have_current_path(new_work_package_path)
    end

    it "opens the project form from a project page that has no create menu" do
      visit project_path(project)

      page.send_keys("n", "w", "p")

      expect(page).to have_current_path(new_project_work_packages_path(project))
    end

    context "without permission to add work packages anywhere" do
      let(:permissions) { %i[view_work_packages] }

      it "leaves the project select closed and a fresh p opens it" do
        visit project_path(project)

        page.send_keys("n", "w", "p")
        sleep 0.5
        top_menu.expect_closed

        page.send_keys("p")
        top_menu.expect_open
      end
    end
  end

  describe "IFC models", with_config: { edition: "bim" } do
    let(:project) { create(:project, enabled_module_names: %w[bim work_package_tracking]) }
    let(:permissions) { %i[view_ifc_models manage_ifc_models view_work_packages] }

    it "puts access key 3 on the first editable row only" do
      create(:ifc_model_minimal_converted, project:, is_default: true)
      create(:ifc_model_minimal_converted, project:, is_default: false)

      visit bcf_project_ifc_models_path(project)

      expect(page).to have_element(:a, class: "icon-edit", count: 2)
      expect(page).to have_element(:a, accesskey: "3", count: 1)
      within("tbody tr:first-child") { expect(page).to have_element(:a, class: "icon-edit", accesskey: "3") }
    end
  end

  describe "project settings" do
    let(:permissions) { %i[edit_project copy_projects view_work_packages] }

    it "carries no access key on the copy action" do
      visit project_settings_general_path(project)

      expect(page).to have_element("data-test-selector": "project-settings--copy", accesskey: false, visible: :all)
    end
  end
end
