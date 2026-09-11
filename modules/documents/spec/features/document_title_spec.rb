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

RSpec.describe "Document title", :js,
               with_settings: { real_time_text_collaboration_enabled: true } do
  let(:project) { create(:project, name: "Test Project") }
  let(:document) { create(:document, :collaborative, title: "Sample Document", project:) }
  let(:user) do
    create(:user, member_with_permissions: { project => %i[view_documents manage_documents] })
  end

  before do
    login_as(user)
    visit document_path(document)
  end

  it "renames the browser tab along with the page header" do
    expect(page).to have_title("Sample Document | Documents | Test Project | #{Setting.app_title}")

    within_test_selector("document-page-header") do
      find("action-menu > button").click
      click_on "Edit title"

      fill_in "Title", with: "Renamed document"
      click_on "Save"

      expect(page).to have_text("Renamed document")
    end

    expect(page).to have_title("Renamed document | Documents | Test Project | #{Setting.app_title}")
  end

  it "keeps the browser tab unchanged when the new title is rejected" do
    within_test_selector("document-page-header") do
      find("action-menu > button").click
      click_on "Edit title"

      fill_in "Title", with: "x" * 256
      click_on "Save"
    end

    expect(page).to have_title("Sample Document | Documents | Test Project | #{Setting.app_title}")
  end
end
