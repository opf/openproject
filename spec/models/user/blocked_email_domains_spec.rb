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

RSpec.describe User, "blocked email domains", with_settings: { blocked_email_domains: ["blocked.com"] } do
  let(:message) { I18n.t("activerecord.errors.messages.blocked_domain") }

  it "rejects a new user on a blocked domain" do
    user = build(:user, mail: "spam@blocked.com")

    expect(user).not_to be_valid
    expect(user.errors[:mail]).to include message
  end

  it "rejects a subdomain of a blocked domain" do
    expect(build(:user, mail: "spam@mail.blocked.com")).not_to be_valid
  end

  it "accepts other domains" do
    expect(build(:user, mail: "customer@example.com")).to be_valid
  end

  it "rejects changing an existing address to a blocked domain" do
    user = create(:user, mail: "customer@example.com")
    user.mail = "spam@blocked.com"

    expect(user).not_to be_valid
    expect(user.errors[:mail]).to include message
  end

  it "keeps users saveable whose domain was blocked after they were created" do
    user = create(:user, mail: "customer@example.com")
    user.update_column :mail, "existing@blocked.com"

    expect(user.reload).to be_valid
    expect(user.update(firstname: "Renamed")).to be true
  end

  describe "invitations" do
    it "refuses to invite a blocked domain" do
      expect(UserInvitation.invite_new_user(email: "spam@blocked.com")).to be_nil
      expect(User.find_by(mail: "spam@blocked.com")).to be_nil
    end

    it "still invites allowed domains" do
      user = UserInvitation.invite_new_user(email: "customer@example.com")

      expect(user).to be_persisted
      expect(user.mail).to eq "customer@example.com"
    end
  end
end
