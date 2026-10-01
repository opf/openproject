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
require_module_spec_helper

require_relative "support/documents_index_page"

RSpec.describe "List Documents",
               :js,
               :selenium do
  shared_let(:project) { create(:project) }
  shared_let(:member_role) { create(:existing_project_role, permissions: [:view_documents]) }
  shared_let(:member) { create(:user, member_with_roles: { project => member_role }) }

  let(:index_page) { Documents::Pages::ListPage.new(project) }

  current_user { member }

  context "with documents" do
    let(:document_types) do
      %w[Specification Report Requirement].map { create(:document_type, name: it) }
    end

    let!(:specifications) { create_list(:document, 3, type: document_types[0], project:) }
    let!(:reports) { create_list(:document, 2, type: document_types[1], project:) }

    it "renders a list of all documents" do
      index_page.visit!

      index_page.expect_documents_listed(specifications + reports)
      index_page.expect_submenu_opened("All documents")
      index_page.expect_pagination_range(from: 1, to: 5, total: 5)
    end

    it "allows filtering by document type" do
      index_page.visit!

      index_page.submenu.click_item("Specification")
      index_page.expect_documents_listed(specifications)
      index_page.expect_submenu_opened("Specification")
      index_page.expect_pagination_range(from: 1, to: 3, total: 3)
    end

    it "allows searching by document title" do
      document = create(:document, title: "Book", project:, type: document_types[0])
      index_page.visit!

      within_test_selector("documents-sub-header") do
        fill_in "title", with: "bo"
        wait_for_network_idle
      end

      index_page.expect_documents_listed([document])
      index_page.expect_pagination_range(from: 1, to: 1, total: 1)

      within_test_selector("documents-sub-header") do
        click_button accessible_name: "Clear"
        wait_for_network_idle
      end

      index_page.expect_documents_listed(specifications + reports)
      index_page.expect_pagination_range(from: 1, to: 6, total: 6)
    end

    it "renders content that is accessible" do
      index_page.visit!

      expect(page).to be_axe_clean
            .within("#content")
            .excluding("opce-principal")
    end
  end

  context "with no documents" do
    it "renders a blank slate" do
      index_page.visit!

      index_page.expect_blank_slate_without_primary_action

      aggregate_failures "renders content that is accessible" do
        expect(page).to be_axe_clean.within("#content")
      end
    end
  end

  context "without view documents permission" do
    let(:user) { create(:user) }

    current_user { user }

    it "renders a not found message" do
      index_page.visit!
      expect(page).to have_text("[Error 404] The page you were trying to access doesn't exist or has been removed.")
    end
  end
end
