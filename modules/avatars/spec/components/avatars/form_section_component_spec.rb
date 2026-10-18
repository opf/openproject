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

RSpec.describe Avatars::FormSectionComponent, type: :component do
  let(:user) { build_stubbed(:user) }
  let(:enable_gravatars) { false }
  let(:enable_local_avatars) { true }

  before do
    allow(Setting)
      .to receive(:plugin_openproject_avatars)
      .and_return("enable_gravatars" => enable_gravatars, "enable_local_avatars" => enable_local_avatars)
  end

  def render_section
    render_inline(
      described_class.new(
        principal: user,
        target_avatar_path: "/users/1/avatar",
        avatar_settings_path: "/users/1/avatar/update_settings"
      )
    )
  end

  it "offers image and initials with an optional text override and a single save action" do
    render_section

    expect(page).to have_field("Image", type: "radio")
    expect(page).to have_checked_field("Initials")
    expect(page).to have_no_field("Custom text", type: "radio")
    expect(page).to have_field("Avatar text", placeholder: OpenProject::Avatars::InitialsSvg.initials_for(user.name))
    expect(page).to have_no_css("input[name='avatar_text'][required]", visible: :all)
    expect(page).to have_no_field("Emoji", type: "radio")
    expect(page).to have_no_field("Gravatar", type: "radio")
    expect(page).to have_css("form[action='/users/1/avatar/update_settings'][enctype='multipart/form-data']")
    expect(page).to have_button("Save")
  end

  it "renders preview images at three application sizes" do
    render_section

    expect(page).to have_css("aside[aria-label='Preview']")
    expect(page).to have_css(".avatars--preview opce-principal", count: 3)
    %w[default medium mini].each do |size|
      selector = ".avatars--preview opce-principal[data-size='\"#{size}\"'][data-hover-card='false'][data-link='false']"
      expect(page).to have_css(selector)
    end
  end

  it "renders a background color field and randomize button" do
    user.pref.avatar_color = "#AABBCC"
    render_section

    expect(page).to have_field("avatar_color", with: "#AABBCC")
    expect(page).to have_css("button[data-test-selector='avatar-randomize-color'][type='button']")
  end

  context "when Gravatar and local avatars are disabled" do
    let(:enable_local_avatars) { false }

    it "offers initials with a text override and background colors" do
      render_section

      expect(page).to have_checked_field("Initials")
      expect(page).to have_no_field("Custom text", type: "radio")
      expect(page).to have_field("Avatar text")
      expect(page).to have_field("avatar_color")
      expect(page).to have_button("Save")
      expect(page).to have_no_field("Gravatar", type: "radio")
      expect(page).to have_no_field("Image", type: "radio")
      expect(page).to have_no_field(type: "file", visible: :all)
    end
  end

  context "when only Gravatar is enabled" do
    let(:enable_gravatars) { true }
    let(:enable_local_avatars) { false }

    it "offers Gravatar but no image upload" do
      render_section

      expect(page).to have_checked_field("Gravatar")
      expect(page).to have_no_field("Image", type: "radio")
      expect(page).to have_no_field(type: "file", visible: :all)
    end
  end

  context "when an image is uploaded" do
    before { allow(user).to receive(:local_avatar_attachment).and_return(true) }

    it "selects image by default and offers deletion" do
      render_section

      expect(page).to have_checked_field("Image")
      expect(page).to have_test_selector("avatar-delete-link")
    end

    it "respects an explicit choice of initials without deleting the image" do
      user.pref.avatar_type = "initials"
      render_section

      expect(page).to have_checked_field("Initials")
      expect(page).to have_css("[data-avatars--settings-image-value='/api/v3/users/#{user.id}/avatar?source=image']")
    end
  end

  context "with an initials override" do
    before do
      user.pref.avatar_type = "initials"
      user.pref.avatar_text = "山田"
    end

    it "selects initials and restores the saved override" do
      render_section

      expect(page).to have_checked_field("Initials")
      expect(page).to have_field("avatar_text", with: "山田")
    end
  end

  context "with an emoji override" do
    before do
      user.pref.avatar_type = "initials"
      user.pref.avatar_text = "👩🏽‍💻"
    end

    it "restores the emoji in the combined text input" do
      render_section

      expect(page).to have_checked_field("Initials")
      expect(page).to have_field("avatar_text", with: "👩🏽‍💻")
      expect(page).to have_no_css("input[name='avatar_text'][maxlength]", visible: :all)
    end
  end

  context "for a group" do
    let(:user) { build_stubbed(:group, avatar_type: "initials", avatar_text: "🚀", avatar_color: "#AABBCC") }
    let(:enable_gravatars) { true }

    it "restores the group's settings and never offers Gravatar" do
      render_section

      expect(page).to have_no_field("Gravatar", type: "radio")
      expect(page).to have_checked_field("Initials")
      expect(page).to have_field("avatar_text", with: "🚀")
      expect(page).to have_field("avatar_color", with: "#AABBCC")
    end
  end
end
