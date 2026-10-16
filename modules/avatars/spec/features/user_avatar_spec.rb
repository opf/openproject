# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User avatar management", :js do
  include Rails.application.routes.url_helpers

  let(:image_base_path) { File.expand_path("#{File.dirname(__FILE__)}/../fixtures/") }
  let(:avatar_management_path) { edit_user_path(target_user) }
  let(:enable_local_avatars) { true }

  def open_avatar_dialog
    find_test_selector("avatar-edit-button").click
    expect(page).to have_css("dialog#avatar-settings-dialog[open]")
  end

  before do
    login_as user
    allow(Setting)
      .to receive(:plugin_openproject_avatars)
      .and_return("enable_gravatars" => false, "enable_local_avatars" => enable_local_avatars)
  end

  context "when user is admin" do
    let(:user) { create(:admin) }
    let(:target_user) { create(:user) }

    it "manages avatars in a dialog above the user details" do
      visit avatar_management_path
      expect(page).to have_test_selector("avatar-edit-button")
      expect(page).to have_no_link("Avatar", href: edit_user_path(target_user, tab: :avatar))
      expect(page).to have_no_field("Initials", type: "radio")

      open_avatar_dialog
      choose "Initials"
      fill_in "avatar_text", with: "🚀"
      click_button "Save"

      expect(page).to have_current_path(avatar_management_path)
      expect(page).to have_text(I18n.t("avatars.message_avatar_updated"))
      open_avatar_dialog
      expect(page).to have_checked_field("Initials")
      expect(target_user.reload.avatar_text).to eq "🚀"
    end

    context "when Gravatar and local avatars are disabled" do
      let(:enable_local_avatars) { false }

      it "keeps the avatar dialog and generated avatars available" do
        visit avatar_management_path
        open_avatar_dialog

        expect(page).to have_checked_field("Initials")
        expect(page).to have_no_field("Gravatar", type: "radio")
        expect(page).to have_no_field("Image", type: "radio")
        choose "Initials"
        fill_in "avatar_text", with: "OP"
        fill_in "avatar_color", with: "#123456"
        click_button "Save"

        expect(page).to have_current_path(avatar_management_path)
        expect(page).to have_text(I18n.t("avatars.message_avatar_updated"))
        expect(target_user.reload.avatar_text).to eq "OP"
        expect(target_user.avatar_color).to eq "#123456"
      end
    end

    it "rejects a file with an invalid format" do
      visit avatar_management_path
      open_avatar_dialog
      choose "Image"

      attach_file("avatar_file_input",
                  UploadedFile.load_from(File.join(image_base_path, "invalid.txt")).path,
                  make_visible: true)

      expect(page).to have_css(".avatars--error-pane", text: "Allowed formats are jpg, png, gif")
    end

    it "deletes an existing custom avatar" do
      target_user.attachments = [build(:avatar_attachment, author: target_user)]

      visit avatar_management_path
      open_avatar_dialog

      accept_alert do
        find_test_selector("avatar-delete-link").click
      end

      expect(page).to have_text(I18n.t(:avatar_deleted), wait: 20)
      expect(target_user.reload.local_avatar_attachment).to be_nil
    end
  end

  context "when user is another user" do
    let(:target_user) { create(:user) }
    let(:user) { create(:user) }

    it "forbids the user to access" do
      visit avatar_management_path
      expect(page).to have_text("[Error 403]")
    end
  end
end
