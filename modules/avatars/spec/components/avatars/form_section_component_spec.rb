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
  let(:enable_local_avatars) { false }

  before do
    allow(Setting)
      .to receive(:plugin_openproject_avatars)
      .and_return("enable_gravatars" => enable_gravatars, "enable_local_avatars" => enable_local_avatars)
  end

  def render_section
    render_inline(described_class.new(user:, target_avatar_path: "/users/1/avatar"))
  end

  context "when avatars are disabled" do
    it "renders nothing" do
      render_section

      expect(page).to have_no_css("h3", text: "Avatar")
    end
  end

  context "when only gravatars are enabled" do
    let(:enable_gravatars) { true }

    it "renders the heading and the Gravatar hint, but no upload trigger" do
      render_section

      expect(page).to have_css("h3", text: "Avatar")
      expect(page).to have_css(".avatars--current-avatar")
      expect(page).to have_css(".Subhead-description", text: "Gravatar")
      expect(page).to have_link("gravatar.com")
      expect(page).to have_no_css(".avatars--upload-trigger")
      expect(page).to have_no_css("opce-avatar-upload-form")
    end
  end

  context "when only local avatars are enabled" do
    let(:enable_local_avatars) { true }

    it "renders the upload trigger pointed at the target path and the local-only hint" do
      render_section

      expect(page).to have_css(".avatars--upload-trigger")
      expect(page).to have_css("opce-avatar-upload-form[target='/users/1/avatar']")
      expect(page).to have_css(".Subhead-description", text: I18n.t("avatars.text_avatar_local_only"))
      expect(page).to have_no_link("gravatar.com")
    end
  end

  context "when both gravatars and local avatars are enabled" do
    let(:enable_gravatars) { true }
    let(:enable_local_avatars) { true }

    it "renders both the Gravatar hint and the upload trigger with the override hint" do
      render_section

      expect(page).to have_link("gravatar.com")
      expect(page).to have_css(".avatars--upload-trigger")
      expect(page).to have_css(".Subhead-description", text: I18n.t("avatars.text_avatar_local"))
    end
  end

  context "when the user already has a local avatar" do
    let(:enable_local_avatars) { true }

    before { allow(user).to receive(:local_avatar_attachment).and_return(true) }

    it "renders the delete control" do
      render_section

      expect(page).to have_css("[data-test-selector='avatar-delete-link']")
    end
  end
end
