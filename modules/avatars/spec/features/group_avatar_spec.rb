# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Group avatar management", :js do
  let(:user) { create(:admin) }
  let(:group) { create(:group) }
  let(:enable_gravatars) { true }
  let(:enable_local_avatars) { true }

  before do
    login_as user
    allow(Setting).to receive(:plugin_openproject_avatars)
      .and_return("enable_gravatars" => enable_gravatars, "enable_local_avatars" => enable_local_avatars)
  end

  it "manages avatars in their own group tab" do
    visit edit_group_path(group)
    expect(page).to have_current_path(edit_group_path(group))
    expect(page).to have_no_field("Initials", type: "radio")

    click_link "Avatar"
    expect(page).to have_no_field("Gravatar", type: "radio")
    choose "Initials"
    fill_in "avatar_text", with: "🇯🇵"
    click_button "Save"

    expect(page).to have_current_path(edit_group_path(group, tab: :avatar))
    expect(page).to have_text(I18n.t("avatars.message_avatar_updated"))
    expect(page).to have_checked_field("Initials")
    expect(page).to have_field("avatar_text", with: "🇯🇵")
    expect(group.reload.avatar_text).to eq "🇯🇵"
    expect(group.avatar_type).to eq "initials"

    fill_in "avatar_text", with: ""
    click_button "Save"

    expect(page).to have_text(I18n.t("avatars.message_avatar_updated"))
    expect(group.reload.avatar_text).to be_nil
    expect(page).to have_css(".avatars--preview text", text: OpenProject::Avatars::InitialsSvg.initials_for(group.name), count: 3)
  end

  context "when Gravatar and local avatars are disabled" do
    let(:enable_gravatars) { false }
    let(:enable_local_avatars) { false }

    it "keeps the avatar tab and generated avatars available" do
      visit edit_group_path(group)
      click_link "Avatar"

      expect(page).to have_checked_field("Initials")
      expect(page).to have_no_field("Gravatar", type: "radio")
      expect(page).to have_no_field("Image", type: "radio")
      choose "Initials"
      fill_in "avatar_text", with: "OP"
      fill_in "avatar_color", with: "#123456"
      click_button "Save"

      expect(page).to have_current_path(edit_group_path(group, tab: :avatar))
      expect(page).to have_text(I18n.t("avatars.message_avatar_updated"))
      expect(group.reload.avatar_text).to eq "OP"
      expect(group.avatar_color).to eq "#123456"
    end
  end
end
