# frozen_string_literal: true

require "spec_helper"
require "mini_magick"

RSpec.describe "My avatar management", :js do
  include Rails.application.routes.url_helpers

  let(:image_base_path) { File.expand_path("../fixtures", __dir__) }
  let(:user) { create(:user) }
  let(:avatar_management_path) { edit_my_avatar_path }
  let(:enable_gravatars) { false }
  let(:enable_local_avatars) { true }

  before do
    login_as user
    allow(Setting)
      .to receive(:plugin_openproject_avatars)
      .and_return("enable_gravatars" => enable_gravatars, "enable_local_avatars" => enable_local_avatars)
  end

  it "opens avatar settings from a separate account menu entry" do
    visit my_account_path

    expect(page).to have_current_path(my_account_path)
    expect(page).to have_no_field("Initials", type: "radio")
    click_link "Avatar"

    expect(page).to have_current_path(avatar_management_path)
    expect(page).to have_checked_field("Initials")
    expect(page).to have_no_field("Custom text", type: "radio")
    expect(page).to have_field("avatar_text", with: "", placeholder: OpenProject::Avatars::InitialsSvg.initials_for(user.name))
    expect(page).to have_css(".avatars--preview-image", count: 3)
  end

  context "when Gravatar is enabled" do
    let(:enable_gravatars) { true }

    it "keeps the management link visible for every avatar option" do
      visit avatar_management_path

      expect(page).to have_checked_field("Gravatar")
      expect(page).to have_link(I18n.t("avatars.manage_gravatar"))

      choose "Initials"
      expect(page).to have_link(I18n.t("avatars.manage_gravatar"))

      choose "Image"
      expect(page).to have_link(I18n.t("avatars.manage_gravatar"))
    end
  end

  context "when Gravatar and local avatars are disabled" do
    let(:enable_local_avatars) { false }

    it "keeps the account menu and text customization available" do
      visit my_account_path
      click_link "Avatar"

      expect(page).to have_checked_field("Initials")
      expect(page).to have_no_field("Gravatar", type: "radio")
      expect(page).to have_no_field("Image", type: "radio")
      choose "Initials"
      fill_in "avatar_text", with: "🚀"
      fill_in "avatar_color", with: "#123456"
      click_button "Save"

      expect(page).to have_text(I18n.t("avatars.message_avatar_updated"))
      expect(page).to have_field("avatar_text", with: "🚀")
      expect(user.reload.avatar_type).to eq "initials"
      expect(user.avatar_color).to eq "#123456"
    end
  end

  it "previews and saves custom text and color, validates text, and switches back to initials" do
    visit avatar_management_path
    choose "Initials"
    fill_in "avatar_text", with: "山田"
    fill_in "avatar_color", with: "#123456"

    expect(page).to have_css(".avatars--preview text", text: "山田", count: 3)
    expect(user.reload.avatar_text).to be_nil
    click_button "Save"

    expect(page).to have_text(I18n.t("avatars.message_avatar_updated"))
    expect(page).to have_field("avatar_text", with: "山田")
    expect(user.reload.avatar_type).to eq "initials"
    expect(user.avatar_color).to eq "#123456"

    fill_in "avatar_text", with: "ABC"
    expect(page).to have_css("#avatar_text:invalid")
    click_button "Save"

    expect(page).to have_field("avatar_text", with: "ABC")
    expect(user.reload.avatar_text).to eq "山田"

    find_field("avatar_text").send_keys(:end, :backspace, :backspace, :backspace)
    expect(page).to have_css(".avatars--preview text", text: OpenProject::Avatars::InitialsSvg.initials_for(user.name), count: 3)
    click_button "Automatic"
    click_button "Save"

    expect(page).to have_text(I18n.t("avatars.message_avatar_updated"))
    expect(user.reload.avatar_type).to eq "initials"
    expect(user.avatar_text).to be_nil
    expect(user.avatar_color).to be_nil
  end

  it "accepts one complete emoji through custom text and rejects combinations" do
    visit avatar_management_path
    choose "Initials"

    ["🇯🇵", "1️⃣", "👨‍👩‍👧‍👦", "e\u0301Ж"].each do |text|
      fill_in "avatar_text", with: text

      expect(page).to have_css("#avatar_text:valid")
      expect(page).to have_css(".avatars--preview text", text:, count: 3)
    end

    fill_in "avatar_text", with: "👩🏽‍💻"

    expect(page).to have_css("#avatar_text:valid")
    expect(page).to have_css(".avatars--preview text", text: "👩🏽‍💻", count: 3)
    expect(user.reload.avatar_text).to be_nil
    click_button "Save"

    expect(page).to have_text(I18n.t("avatars.message_avatar_updated"))
    expect(user.reload.avatar_type).to eq "initials"
    expect(user.avatar_text).to eq "👩🏽‍💻"

    ["🚀🚀", "A🚀"].each do |text|
      fill_in "avatar_text", with: text
      expect(page).to have_css("#avatar_text:invalid")
      click_button "Save"

      expect(page).to have_field("avatar_text", with: text)
      expect(user.reload.avatar_text).to eq "👩🏽‍💻"
    end
  end

  it "validates, previews, saves, resizes, and deletes an image" do
    visit avatar_management_path
    choose "Image"
    attach_file("avatar_file_input", File.join(image_base_path, "invalid.txt"), make_visible: true)

    expect(page).to have_css(".avatars--error-pane", text: I18n.t(:wrong_file_format))
    expect(page).to have_button("Save", disabled: true)
    attach_file("avatar_file_input", File.join(image_base_path, "too_big.jpg"), make_visible: true)

    expect(page).to have_button("Save", disabled: false)
    expect(page).to have_css(".avatars--preview img[src^='blob:']", count: 3)
    expect(user.local_avatar_attachment).to be_nil
    click_button "Save"

    expect(page).to have_test_selector("avatar-delete-link", wait: 20)
    expect(page).to have_css(".avatars--preview img[src$='/avatar?source=image']", count: 3)
    wait_for { page.evaluate_script("document.querySelector('.avatars--preview img').naturalWidth") }.to eq 128
    expect(user.reload.avatar_type).to eq "image"
    image = MiniMagick::Image.open(user.local_avatar_attachment.file.path)
    expect(image.dimensions).to eq [128, 128]

    choose "Initials"
    click_button "Save"
    expect(page).to have_text(I18n.t("avatars.message_avatar_updated"))
    expect(page).to have_checked_field("Initials")
    expect(user.reload.local_avatar_attachment).to be_present

    choose "Image"
    accept_alert { find_test_selector("avatar-delete-link").click }

    expect(page).to have_no_test_selector("avatar-delete-link", wait: 20)
    expect(user.reload.local_avatar_attachment).to be_nil
  end
end
