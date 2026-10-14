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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Users::Authentication do
  describe ".find_user_by_api_key", with_settings: { api_tokens_enabled: true } do
    let(:user) { create(:user) }
    let(:scopes) { %w[api_v3] }
    let(:token) { create(:api_token, user:, scopes:) }

    subject(:found_user) { described_class.find_user_by_api_key(token.plain_value, scope: :api_v3) }

    it "returns the user of a token with the scope" do
      expect(found_user).to eq(user)
    end

    context "with a token without the scope" do
      let(:scopes) { %w[mcp] }

      it { is_expected.to be_nil }
    end

    context "with an unknown key" do
      subject(:found_user) { described_class.find_user_by_api_key("#{token.plain_value}abc", scope: :api_v3) }

      it { is_expected.to be_nil }
    end

    context "with a locked user" do
      let(:user) { create(:user, status: :locked) }

      it { is_expected.to be_nil }
    end

    context "with API tokens disabled", with_settings: { api_tokens_enabled: false } do
      it { is_expected.to be_nil }
    end

    context "for an admin", with_flag: { admin_privilege_elevation: true } do
      let(:user) { create(:admin) }

      it "returns the admin without an elevation" do
        expect(found_user.admin_elevation).to be_a(Users::AdminElevation::None)
      end

      context "with the admin_elevation scope" do
        let(:scopes) { %w[api_v3 admin_elevation] }

        it "returns the admin elevated everywhere" do
          expect(found_user.admin_elevation).to be_a(Users::AdminElevation::Everywhere)
        end
      end
    end
  end

  describe ".find_user_by_rss_key" do
    let(:user) { create(:user) }
    let(:rss_key) { user.rss_key }

    subject(:found_user) { described_class.find_user_by_rss_key(rss_key) }

    context "with feeds enabled", with_settings: { feeds_enabled: true } do
      it { is_expected.to eq(user) }

      context "with a locked user" do
        let(:user) { create(:user, status: :locked) }

        it { is_expected.to be_nil }
      end
    end

    context "with feeds disabled", with_settings: { feeds_enabled: false } do
      it { is_expected.to be_nil }
    end
  end
end
