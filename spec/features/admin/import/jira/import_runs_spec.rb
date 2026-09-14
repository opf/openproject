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

RSpec.describe "Jira import runs page", :js do
  shared_let(:admin) { create(:admin) }
  shared_let(:author) { create(:user, firstname: "Jane", lastname: "Doe") }
  let!(:jira) { create(:jira, name: "My Jira") }
  let!(:jira_import) do
    create(:jira_import,
           jira:,
           author:,
           projects: [{ "name" => "Project Alpha" }, { "name" => "Project Beta" }])
  end

  current_user { admin }

  before { visit admin_import_jira_path(jira) }

  describe "header action menu" do
    it "opens the edit configuration entry from the actions menu" do
      expect(page).to have_no_link("Edit configuration")

      page.find_test_selector("jira-configuration-action-menu").click

      within "anchored-position" do
        expect(page).to have_link("Edit configuration", href: edit_admin_import_jira_path(jira))
      end
    end
  end

  describe "creator column" do
    it "shows the import run author next to the avatar" do
      expect(page).to have_text("Creator")
      expect(page).to have_text("Jane Doe")
      expect(page).to have_css(".op-avatar")
    end
  end

  describe "projects column" do
    it "renders the project list inside an expandable text with an ellipsis expander" do
      within "[data-controller='expandable-text']" do
        expect(page).to have_text("Project Alpha, Project Beta")
        expect(page).to have_button(class: "ellipsis-expander", visible: :all)
      end
    end
  end
end
