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

# The avatar section's rendering across the gravatar/local/both/none settings is
# covered exhaustively by Avatars::FormSectionComponent's component spec. These
# feature specs only exercise what needs a real browser and the users avatar
# controller: client-side file validation, the delete round-trip, and access control.
RSpec.describe "User avatar management", :js do
  include Rails.application.routes.url_helpers

  let(:image_base_path) { File.expand_path("#{File.dirname(__FILE__)}/../fixtures/") }
  let(:avatar_management_path) { edit_user_path(target_user) }

  before do
    login_as user
    allow(Setting)
      .to receive(:plugin_openproject_avatars)
      .and_return("enable_gravatars" => false, "enable_local_avatars" => true)
  end

  context "when user is admin" do
    let(:user) { create(:admin) }
    let(:target_user) { create(:user) }

    it "rejects a file with an invalid format" do
      visit avatar_management_path

      attach_file("avatar_file_input",
                  UploadedFile.load_from(File.join(image_base_path, "invalid.txt")).path,
                  make_visible: true)

      expect(page).to have_css(".avatars--error-pane", text: "Allowed formats are jpg, png, gif")
    end

    it "deletes an existing custom avatar" do
      target_user.attachments = [build(:avatar_attachment, author: target_user)]

      visit avatar_management_path

      accept_alert do
        find_test_selector("avatar-delete-link").click
      end

      expect(page).to have_no_test_selector("avatar-delete-link", wait: 20)
    end
  end

  context "when user is another user" do
    let(:target_user) { create(:user) }
    let(:user) { create(:user) }

    it "forbids the user to access" do
      visit edit_user_path(target_user)
      expect(page).to have_text("[Error 403]")
    end
  end
end
