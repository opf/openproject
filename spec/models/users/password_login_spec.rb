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

RSpec.describe Users::PasswordLogin do
  shared_let(:provider) { create(:oidc_provider) }
  shared_let(:sso_user) { create(:user, login: "sso_user", authentication_provider: provider) }
  shared_let(:internal_user) { create(:user, login: "internal") }

  describe ".mode" do
    it "defaults to all" do
      expect(described_class.mode).to eq described_class::ALL
    end

    it "reads the writable setting", with_settings: { password_login: "except_sso" } do
      expect(described_class.mode).to eq described_class::EXCEPT_SSO
    end

    it "maps the legacy disable_password_login env to a locked none setting",
       :settings_reset,
       with_env: { "OPENPROJECT_DISABLE__PASSWORD__LOGIN" => "true" } do
      reset(:disable_password_login)
      reset(:password_login)

      expect(Setting.password_login).to eq described_class::NONE
      expect(Setting.password_login_writable?).to be false
      expect(described_class.mode).to eq described_class::NONE
    end
  end

  describe ".allowed?" do
    context "with except_sso", with_settings: { password_login: "except_sso" } do
      it "refuses OmniAuth-linked users" do
        expect(described_class.allowed?(sso_user)).to be false
      end

      it "allows internal users" do
        expect(described_class.allowed?(internal_user)).to be true
      end
    end

    context "with none", with_settings: { password_login: "none" } do
      it "refuses everyone" do
        expect(described_class.allowed?(internal_user)).to be false
        expect(described_class.allowed?(sso_user)).to be false
      end
    end
  end

  describe ".bypass?" do
    context "with a user id on the list",
            with_settings: { password_login: "except_sso" } do
      before do
        Setting.password_login_bypass_principal_ids = [sso_user.id.to_s]
      end

      it "allows that user" do
        expect(described_class.bypass?(sso_user)).to be true
        expect(described_class.allowed?(sso_user)).to be true
      end
    end

    context "with a group and a descendant member",
            with_settings: { password_login: "none" } do
      let!(:root_group) { create(:group) }
      let!(:child_group) { create(:group, members: [internal_user], parent: root_group) }

      before do
        Setting.password_login_bypass_principal_ids = [root_group.id.to_s]
      end

      it "includes users of descendant groups, not ancestor members" do
        expect(described_class.bypass?(internal_user)).to be true
        expect(described_class.expanded_group_ids).to contain_exactly(root_group.id, child_group.id)
      end
    end

    context "with an ENV login overlay",
            with_config: { password_login: "none", password_login_bypass_logins: ["SSO_User"] } do
      it "matches logins case-insensitively" do
        expect(described_class.bypass?(sso_user)).to be true
        expect(described_class.allowed?(sso_user)).to be true
      end
    end
  end

  describe ".internal_login_available?" do
    it "is false in mode none with an empty whitelist", with_settings: { password_login: "none" } do
      expect(described_class.internal_login_available?).to be false
    end

    it "is true in mode none when a principal is listed", with_settings: { password_login: "none" } do
      Setting.password_login_bypass_principal_ids = [internal_user.id.to_s]

      expect(described_class.internal_login_available?).to be true
    end
  end
end
