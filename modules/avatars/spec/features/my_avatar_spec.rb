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
require "mini_magick"

# The avatar section's rendering across the gravatar/local/both/none settings is
# covered by Avatars::FormSectionComponent's component spec. This feature spec only
# exercises the self-service round-trip that needs a real browser and the my-avatar
# controller: client-side validation, upload, server-side resize, and deletion.
RSpec.describe "My avatar management", :js do
  include Rails.application.routes.url_helpers

  let(:image_base_path) { File.expand_path("#{File.dirname(__FILE__)}/../fixtures/") }
  let(:user) { create(:user) }
  let(:avatar_management_path) { my_account_path }

  before do
    login_as user
    allow(Setting)
      .to receive(:plugin_openproject_avatars)
      .and_return("enable_gravatars" => false, "enable_local_avatars" => true)
  end

  it "validates the format, then uploads, resizes and deletes a custom avatar" do
    visit avatar_management_path
    expect(page).to have_css(".avatars--upload-trigger")

    # An invalid file is rejected client-side
    attach_file("avatar_file_input",
                UploadedFile.load_from(File.join(image_base_path, "invalid.txt")).path,
                make_visible: true)

    expect(page).to have_css(".avatars--error-pane", text: "Allowed formats are jpg, png, gif")

    # A valid image is uploaded as soon as it is selected
    visit avatar_management_path
    attach_file("avatar_file_input",
                UploadedFile.load_from(File.join(image_base_path, "too_big.jpg")).path,
                make_visible: true)

    # It is uploaded and resized to the avatar dimensions
    expect(page).to have_test_selector("avatar-delete-link", wait: 20)
    avatar_path = user.local_avatar_attachment.file.path
    content_type = OpenProject::ContentTypeDetector.new(avatar_path).detect
    image = MiniMagick::Image.open(avatar_path)

    expect(image.dimensions).to eq [128, 128]
    expect(content_type).to eq("image/jpeg")

    # And can be deleted again
    accept_alert do
      find_test_selector("avatar-delete-link").click
    end

    expect(page).to have_no_test_selector("avatar-delete-link", wait: 20)
  end
end
