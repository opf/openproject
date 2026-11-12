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

RSpec.describe "Group avatar management", :js do
  let(:user) { create(:admin) }
  let(:group) { create(:group) }
  let(:enable_gravatars) { true }
  let(:enable_local_avatars) { true }

  def open_avatar_dialog
    find_test_selector("avatar-edit-button").click
    expect(page).to have_css("dialog#avatar-settings-dialog[open]")
  end

  def save_avatar
    within("dialog#avatar-settings-dialog") { click_button "Save" }
  end

  before do
    login_as user
    allow(Setting).to receive(:plugin_openproject_avatars)
      .and_return("enable_gravatars" => enable_gravatars, "enable_local_avatars" => enable_local_avatars)
  end

  it "manages avatars in a dialog above the group details" do
    visit edit_group_path(group)
    expect(page).to have_test_selector("avatar-edit-button")
    expect(page).to have_no_link("Avatar", exact: true)
    expect(page).to have_no_field("Initials", type: "radio")

    open_avatar_dialog
    expect(page).to have_no_field("Gravatar", type: "radio")
    choose "Initials"
    fill_in "avatar_text", with: "🇯🇵"
    save_avatar

    expect(page).to have_current_path(edit_group_path(group))
    expect(page).to have_text(I18n.t("avatars.message_avatar_updated"))
    open_avatar_dialog
    expect(page).to have_checked_field("Initials")
    expect(page).to have_field("avatar_text", with: "🇯🇵")
    expect(group.reload.avatar_text).to eq "🇯🇵"
    expect(group.avatar_type).to eq "initials"

    fill_in "avatar_text", with: ""
    save_avatar

    expect(page).to have_text(I18n.t("avatars.message_avatar_updated"))
    expect(group.reload.avatar_text).to be_nil
    open_avatar_dialog
    expect(page).to have_css(".avatars--preview img[src^='data:image/svg+xml']", count: 3) do |image|
      svg = Nokogiri::XML(CGI.unescape(image[:src].split(",", 2).last), &:strict)
      svg.at_css("text").text == OpenProject::Avatars::InitialsSvg.initials_for(group.name)
    end
  end

  context "when Gravatar and local avatars are disabled" do
    let(:enable_gravatars) { false }
    let(:enable_local_avatars) { false }

    it "keeps the avatar dialog and generated avatars available" do
      visit edit_group_path(group)
      open_avatar_dialog

      expect(page).to have_checked_field("Initials")
      expect(page).to have_no_field("Gravatar", type: "radio")
      expect(page).to have_no_field("Image", type: "radio")
      choose "Initials"
      fill_in "avatar_text", with: "OP"
      fill_in "avatar_color", with: "#123456"
      save_avatar

      expect(page).to have_current_path(edit_group_path(group))
      expect(page).to have_text(I18n.t("avatars.message_avatar_updated"))
      expect(group.reload.avatar_text).to eq "OP"
      expect(group.avatar_color).to eq "#123456"
    end
  end
end
