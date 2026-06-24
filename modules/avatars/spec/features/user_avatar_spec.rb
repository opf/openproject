# frozen_string_literal: true

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
