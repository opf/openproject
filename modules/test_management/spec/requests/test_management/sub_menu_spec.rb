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

RSpec.describe "Test management sidebar submenu", type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs] }) }

  let(:current_user) { user }

  before { login_as(current_user) }

  def frame_src
    response.parsed_body.at_css("turbo-frame#test_management_sub_menu")&.[]("src")
  end

  def submenu
    response.parsed_body
  end

  def section_links
    submenu.css('[data-test-selector="op-submenu--item-action"]')
  end

  describe "main menu" do
    it "shows the arrow, the back header and the submenu frame for the current section" do
      get project_test_management_test_cases_path(project)

      expect(response).to have_http_status(:ok)
      entry = response.parsed_body.at_css('li[data-name="test_management"]')
      expect(entry["class"]).to include("open")
      expect(entry.at_css('[data-test-selector="main-menu-toggler--test_management"]')).to be_present
      expect(entry.at_css('[data-test-selector="main-menu--arrow-left-to-project"]')).to be_present
      expect(frame_src).to include("/projects/#{project.identifier}/test_management/menu")
      expect(frame_src).to include("section=cases")
    end

    it "has no flat child entries" do
      get project_test_management_test_cases_path(project)

      %w[test_management_cases test_management_runs test_management_folder_tree].each do |name|
        expect(response.body).not_to include(%(data-name="#{name}"))
      end
    end

    it "passes the section of runs" do
      get project_test_management_test_runs_path(project)

      expect(frame_src).to include("section=runs")
    end
  end

  describe "GET menu" do
    it "lists the sections and highlights the current one" do
      get project_test_management_menu_path(project, section: "runs")

      expect(response).to have_http_status(:ok)
      expect(section_links.pluck("href")).to eq([project_test_management_test_cases_path(project),
                                                 project_test_management_test_runs_path(project)])
      expect(section_links.select { it["class"].include?("selected") }.pluck("href"))
        .to eq([project_test_management_test_runs_path(project)])
    end

    context "with view_test_cases only" do
      let(:current_user) { create(:user, member_with_permissions: { project => %i[view_test_cases] }) }

      it "hides what the user may not open" do
        get project_test_management_menu_path(project, section: "cases")

        expect(section_links.pluck("href")).to eq([project_test_management_test_cases_path(project)])
      end
    end

    it "keeps the folder tree in the page with the split pane layout" do
      create(:tm_suite, project:)

      get project_test_management_menu_path(project, section: "cases")
      expect(submenu.at_css('[data-test-selector="tm-sub-menu-folders"]')).to be_nil
    end

    context "without access to the module" do
      let(:current_user) { create(:user) }

      it "is refused" do
        get project_test_management_menu_path(project, section: "cases")
        expect(response.status).to be_in([403, 404])
      end
    end
  end
end
