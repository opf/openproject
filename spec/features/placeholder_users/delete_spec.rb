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

RSpec.describe "delete placeholder user", :js do
  shared_let(:placeholder_user) { create(:placeholder_user, name: "UX Developer") }

  shared_examples "placeholders delete flow" do
    it "can delete name" do
      visit placeholder_user_path(placeholder_user)

      expect(page).to have_test_selector "placeholder-user--delete-button", text: "Delete"

      visit edit_placeholder_user_path(placeholder_user)

      expect(page).to have_test_selector "placeholder-user--delete-button", text: "Delete"
      click_on "Delete"

      # Expect to be on delete confirmation
      expect(page).to have_css(".danger-zone--verification button[disabled]")
      fill_in "name_verification", with: placeholder_user.name

      expect(page).to have_css(".danger-zone--verification button:not([disabled])")
      click_on "Delete"

      expect(page).to have_css(".op-toast.-info", text: I18n.t(:notice_deletion_scheduled))

      # The user is still there
      placeholder_user.reload

      perform_enqueued_jobs

      expect { placeholder_user.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context "as admin" do
    current_user { create(:admin) }

    it_behaves_like "placeholders delete flow"
  end

  context "as user with global permission" do
    current_user { create(:user, global_permissions: %i[manage_placeholder_user]) }

    it_behaves_like "placeholders delete flow"
  end

  context "as user with global permission, but placeholder in an invisible project" do
    current_user { create(:user, global_permissions: %i[manage_placeholder_user]) }

    let!(:project) { create(:project) }
    let!(:member) do
      create(:member,
             principal: placeholder_user,
             project:,
             roles: [create(:project_role)])
    end

    it "returns an error when trying to delete and disables the button" do
      visit deletion_info_placeholder_user_path(placeholder_user)
      expect(page).to have_content I18n.t("placeholder_users.right_to_manage_members_missing").strip

      visit placeholder_user_path(placeholder_user)

      expect(page).to have_css("[data-test-selector='placeholder-user--delete-button'][disabled='disabled']", text: "Delete")

      visit edit_placeholder_user_path(placeholder_user)

      expect(page).to have_css("[data-test-selector='placeholder-user--delete-button'][disabled='disabled']", text: "Delete")
    end
  end

  context "as user without global permission" do
    current_user { create(:user) }

    it "returns an error" do
      visit deletion_info_placeholder_user_path(placeholder_user)
      expect(page).to have_text "You are not authorized to access this page."
    end
  end
end
