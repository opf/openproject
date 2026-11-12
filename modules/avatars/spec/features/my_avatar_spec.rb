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

RSpec.describe "My avatar management", :js do
  include Rails.application.routes.url_helpers

  let(:image_base_path) { File.expand_path("../fixtures", __dir__) }
  let(:user) { create(:user) }
  let(:enable_gravatars) { false }
  let(:enable_local_avatars) { true }

  def avatar_preview(text, color: nil, text_color: nil, font_size: nil)
    have_css(".avatars--preview img[src^='data:image/svg+xml']", count: 3) do |image|
      svg = Nokogiri::XML(CGI.unescape(image[:src].split(",", 2).last), &:strict)
      svg.at_css("text").text == text &&
        (color.nil? || svg.at_css("rect")["fill"] == color) &&
        (text_color.nil? || svg.at_css("text")["fill"] == text_color) &&
        (font_size.nil? || svg.at_css("text")["font-size"] == font_size.to_s)
    end
  end

  def open_avatar_dialog
    find_test_selector("avatar-edit-button").click
    expect(page).to have_css("dialog#avatar-settings-dialog[open]")
  end

  def save_avatar
    within("dialog#avatar-settings-dialog") { click_button "Save" }
  end

  def visit_avatar_settings
    visit my_account_path
    open_avatar_dialog
  end

  before do
    login_as user
    allow(Setting)
      .to receive(:plugin_openproject_avatars)
      .and_return("enable_gravatars" => enable_gravatars, "enable_local_avatars" => enable_local_avatars)
  end

  it "opens avatar settings in a dialog from the avatar on the account page" do
    visit my_account_path

    expect(page).to have_test_selector("avatar-edit-button")
    expect(find_test_selector("avatar-edit-button")).to have_css(".avatars--edit-badge .octicon-pencil", visible: :visible)
    expect(page).to have_no_link("Avatar", exact: true)
    expect(page).to have_no_field("Initials", type: "radio")
    find_test_selector("avatar-edit-button").hover
    expect(page).to have_css("tool-tip[for='avatar-edit-button']", text: I18n.t("avatars.edit_avatar"), visible: :visible)
    open_avatar_dialog

    expect(page).to have_current_path(my_account_path)
    expect(page).to have_checked_field("Initials")
    expect(page).to have_no_field("Custom text", type: "radio")
    expect(page).to have_field("avatar_text", with: "", placeholder: OpenProject::Avatars::InitialsSvg.initials_for(user.name))
    expect(page).to have_css(".avatars--preview .op-avatar", count: 3)
    expect(page).to have_field("avatar_color")
    expect(page).to have_no_button(I18n.t(:label_choose_avatar))

    choose "Image"
    expect(page).to have_button(I18n.t(:label_choose_avatar))
    expect(page).to have_no_field("avatar_text")
    expect(page).to have_no_field("avatar_color")

    choose "Initials"
    expect(page).to have_field("avatar_text")
    expect(page).to have_no_button(I18n.t(:label_choose_avatar))

    click_button I18n.t(:button_cancel)
    expect(page).to have_no_css("dialog#avatar-settings-dialog[open]")
  end

  context "when Gravatar is enabled" do
    let(:enable_gravatars) { true }

    it "keeps the management link visible for every avatar option" do
      visit_avatar_settings

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

    it "keeps the avatar dialog and text customization available" do
      visit_avatar_settings

      expect(page).to have_checked_field("Initials")
      expect(page).to have_no_field("Gravatar", type: "radio")
      expect(page).to have_no_field("Image", type: "radio")
      choose "Initials"
      fill_in "avatar_text", with: "🚀"
      fill_in "avatar_color", with: "#123456"
      save_avatar

      expect(page).to have_text(I18n.t("avatars.message_avatar_updated"))

      open_avatar_dialog
      expect(page).to have_field("avatar_text", with: "🚀")
      expect(user.reload.avatar_type).to eq "initials"
      expect(user.avatar_color).to eq "#123456"
    end
  end

  it "previews and saves custom text and color, validates text, and switches back to initials" do
    visit_avatar_settings
    choose "Initials"
    fill_in "avatar_text", with: "本田"
    fill_in "avatar_color", with: "#123456"

    expect(page).to have_css("#avatar_text:valid")
    expect(page).to avatar_preview("本田", color: "#123456", text_color: "#ffffff", font_size: 28)
    expect(user.reload.avatar_text).to be_nil
    fill_in "avatar_color", with: "#D1F0FF"
    expect(page).to avatar_preview("本田", color: "#D1F0FF", text_color: "#1f2328")
    save_avatar

    expect(page).to have_text(I18n.t("avatars.message_avatar_updated"))

    open_avatar_dialog
    expect(page).to have_field("avatar_text", with: "本田")
    expect(user.reload.avatar_type).to eq "initials"
    expect(user.avatar_color).to eq "#D1F0FF"
    expect(page).to avatar_preview("本田", color: "#D1F0FF", text_color: "#1f2328")

    find_test_selector("avatar-randomize-color").click
    random_color = find_field("avatar_color").value
    expect(random_color).not_to eq "#D1F0FF"
    expect(random_color).to match(/\A#[0-9A-F]{6}\z/)
    text_color = Color.new(hexcode: random_color).contrasting_font_color(light: "#ffffff", dark: "#1f2328")
    expect(page).to avatar_preview("本田", color: random_color, text_color:)
    save_avatar
    expect(page).to have_text(I18n.t("avatars.message_avatar_updated"))
    open_avatar_dialog
    expect(user.reload.avatar_color).to eq random_color
    expect(page).to avatar_preview("本田", color: random_color, text_color:)

    fill_in "avatar_text", with: "ABC"
    expect(page).to have_css("#avatar_text:invalid")
    save_avatar

    expect(page).to have_field("avatar_text", with: "ABC")
    expect(user.reload.avatar_text).to eq "本田"

    find_field("avatar_text").send_keys(:end, :backspace, :backspace, :backspace)
    expect(page).to avatar_preview(OpenProject::Avatars::InitialsSvg.initials_for(user.name))
    fill_in "avatar_color", with: ""
    save_avatar

    expect(page).to have_text(I18n.t("avatars.message_avatar_updated"))

    open_avatar_dialog
    expect(user.reload.avatar_type).to eq "initials"
    expect(user.avatar_text).to be_nil
    expect(user.avatar_color).to be_nil
    expect(page).to avatar_preview(OpenProject::Avatars::InitialsSvg.initials_for(user.name),
                                   color: OpenProject::Avatars::InitialsSvg.color_for(user),
                                   text_color: "#ffffff")
  end

  it "accepts up to two visible characters without splitting combined characters" do
    visit_avatar_settings
    choose "Initials"

    ["🇯🇵", "1️⃣", "👨‍👩‍👧‍👦", "e\u0301Ж"].each do |text|
      fill_in "avatar_text", with: text

      expect(page).to have_css("#avatar_text:valid")
      expect(page).to avatar_preview(text)
    end

    fill_in "avatar_text", with: "👩🏽‍💻"

    expect(page).to have_css("#avatar_text:valid")
    expect(page).to avatar_preview("👩🏽‍💻")
    expect(user.reload.avatar_text).to be_nil

    ["本田", "OP", "👩🏽‍💻🇯🇵"].each do |text|
      fill_in "avatar_text", with: text

      expect(page).to have_css("#avatar_text:valid")
      expect(page).to avatar_preview(text, font_size: 28)
    end

    save_avatar

    expect(page).to have_text(I18n.t("avatars.message_avatar_updated"))

    open_avatar_dialog
    expect(user.reload.avatar_type).to eq "initials"
    expect(user.avatar_text).to eq "👩🏽‍💻🇯🇵"

    ["本田技", "🚀🚀🚀"].each do |text|
      fill_in "avatar_text", with: text
      expect(page).to have_css("#avatar_text:invalid")
      save_avatar

      expect(page).to have_field("avatar_text", with: text)
      expect(user.reload.avatar_text).to eq "👩🏽‍💻🇯🇵"
    end
  end

  it "validates, previews, saves, resizes, and deletes an image" do
    visit_avatar_settings
    choose "Image"
    attach_file("avatar_file_input", File.join(image_base_path, "invalid.txt"), make_visible: true)

    expect(page).to have_css(".InlineMessage", text: I18n.t(:wrong_file_format))
    expect(page).to have_button("Save", disabled: true)
    attach_file("avatar_file_input", File.join(image_base_path, "too_big.jpg"), make_visible: true)

    expect(page).to have_button("Save", disabled: false)
    expect(page).to have_css(".avatars--preview img[src^='blob:']", count: 3)
    expect(user.local_avatar_attachment).to be_nil
    save_avatar

    expect(page).to have_text(I18n.t("avatars.message_avatar_updated"), wait: 20)
    open_avatar_dialog
    find(:button, accessible_name: I18n.t(:button_actions)).click
    expect(page).to have_test_selector("avatar-delete-link")
    expect(page).to have_css(".avatars--preview img[src$='/avatar?source=image']", count: 3)
    wait_for { page.evaluate_script("document.querySelector('.avatars--preview img').naturalWidth") }.to eq 128
    expect(user.reload.avatar_type).to eq "image"
    image = MiniMagick::Image.open(user.local_avatar_attachment.file.path)
    expect(image.dimensions).to eq [128, 128]

    choose "Initials"
    save_avatar
    expect(page).to have_text(I18n.t("avatars.message_avatar_updated"))
    open_avatar_dialog
    expect(page).to have_checked_field("Initials")
    expect(user.reload.local_avatar_attachment).to be_present

    choose "Image"
    find(:button, accessible_name: I18n.t(:button_actions)).click
    accept_alert { find_test_selector("avatar-delete-link").click }

    expect(page).to have_text(I18n.t(:avatar_deleted), wait: 20)
    expect(user.reload.local_avatar_attachment).to be_nil
    open_avatar_dialog
    choose "Image"
    expect(page).to have_no_test_selector("avatar-delete-link")
  end
end
