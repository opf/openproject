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

require_relative "../../spec_helper"

RSpec.describe Avatars::MyAvatarController do
  let(:current_user) { create(:user) }
  let(:enabled) { true }

  before do
    allow(User).to receive(:current).and_return current_user
    allow(OpenProject::Avatars::AvatarManager).to receive(:local_avatars_enabled?).and_return enabled
  end

  describe "#update_settings" do
    it "saves the selected source, characters, and color together" do
      patch :update_settings, params: { avatar_type: "initials", avatar_text: "👩🏽‍💻", avatar_color: "#abc" }

      expect(response).to redirect_to my_account_path
      expect(current_user.reload.avatar_type).to eq "initials"
      expect(current_user.avatar_text).to eq "👩🏽‍💻"
      expect(current_user.avatar_color).to eq "#AABBCC"
    end

    it "rejects more than two emoji without saving the color" do
      patch :update_settings, params: { avatar_type: "initials", avatar_text: "🚀🚀🚀", avatar_color: "#abc" }

      expect(flash[:error]).to be_present
      expect(current_user.reload.avatar_type).to be_nil
      expect(current_user.avatar_color).to be_nil
    end

    it "uses default initials without an override" do
      current_user.pref.update!(settings: { avatar_type: "initials", avatar_text: "OP" })
      patch :update_settings, params: { avatar_type: "initials", avatar_text: " " }

      expect(flash[:notice]).to be_present
      expect(current_user.reload.avatar_type).to eq "initials"
      expect(current_user.avatar_text).to be_nil
    end

    it "trims Unicode spaces around the characters" do
      patch :update_settings, params: { avatar_type: "initials", avatar_text: " 山田　" }

      expect(flash[:notice]).to be_present
      expect(current_user.reload.avatar_text).to eq "山田"
    end

    it "rejects the image source without an image" do
      patch :update_settings, params: { avatar_type: "image" }

      expect(flash[:error]).to eq I18n.t("avatars.image_required")
      expect(current_user.reload.avatar_type).to be_nil
    end

    it "rejects a source disabled by the administrator" do
      allow(OpenProject::Avatars::AvatarManager).to receive(:gravatar_enabled?).and_return false

      patch :update_settings, params: { avatar_type: "gravatar" }

      expect(flash[:error]).to be_present
      expect(current_user.reload.avatar_type).to be_nil
    end

    context "when Gravatar and local avatars are disabled" do
      let(:enabled) { false }

      before do
        allow(OpenProject::Avatars::AvatarManager).to receive(:gravatar_enabled?).and_return false
      end

      it "saves custom text and background color" do
        patch :update_settings, params: { avatar_type: "initials", avatar_text: "🚀", avatar_color: "#abc" }

        expect(flash[:notice]).to be_present
        expect(current_user.reload.avatar_type).to eq "initials"
        expect(current_user.avatar_text).to eq "🚀"
        expect(current_user.avatar_color).to eq "#AABBCC"
      end

      it "rejects the disabled image option" do
        patch :update_settings, params: { avatar_type: "image" }

        expect(flash[:error]).to be_present
        expect(current_user.reload.avatar_type).to be_nil
      end
    end

    context "when not logged in" do
      let(:current_user) { User.anonymous }

      it "requires login" do
        patch :update_settings, params: { avatar_type: "initials" }

        expect(response).to have_http_status :redirect
      end
    end
  end
end
