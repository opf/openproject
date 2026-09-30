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

RSpec.describe Token::AutoLogin do
  let(:user) { create(:user) }

  before do
    # Enable autologin for tests
    allow(Setting).to receive(:autologin).and_return(30)
  end

  describe "inheritance and behavior" do
    it "inherits from HashedToken" do
      expect(described_class.superclass).to eq(Token::HashedToken)
    end

    it "includes ExpirableToken" do
      expect(described_class.included_modules).to include(Token::ExpirableToken)
    end

    it "allows multiple values" do
      token = described_class.new(user:)
      expect(token.send(:single_value?)).to be false
    end
  end

  describe "creation" do
    it "creates a valid autologin token" do
      token = described_class.create(user:)

      expect(token).to be_valid
      expect(token.user).to eq(user)
      expect(token.value).to be_present
      expect(token.plain_value).to be_present
    end

    it "generates a unique token value" do
      token1 = described_class.create(user:)
      token2 = described_class.create(user:)

      expect(token1.value).not_to eq(token2.value)
      expect(token1.plain_value).not_to eq(token2.plain_value)
    end

    it "sets expiration based on autologin setting" do
      allow(Setting).to receive(:autologin).and_return(30)

      token = described_class.create(user:)

      expect(token.expires_on).to be_within(1.second).of(30.days.from_now)
    end

    it "can store browser and platform data" do
      data = { browser: "Firefox", browser_version: "142", platform: "macOS" }
      token = described_class.create(user:, data:)

      expect(token.data[:browser]).to eq("Firefox")
      expect(token.data[:browser_version]).to eq("142")
      expect(token.data[:platform]).to eq("macOS")
    end
  end

  describe "validation" do
    it "requires a user" do
      token = described_class.new

      expect(token).not_to be_valid
      expect(token.errors[:user]).to include("must exist")
    end

    it "validates token value uniqueness" do
      token1 = described_class.create(user:)
      token2 = described_class.new(user:, value: token1.value)

      expect(token2).not_to be_valid
      expect(token2.errors[:value]).to include("has already been taken.")
    end
  end

  describe ".find_valid_token" do
    let(:token) { described_class.create(user:) }

    it "finds a valid token with correct plaintext value" do
      found_token = described_class.find_valid_token(token.plain_value)
      expect(found_token).to eq(token)
    end

    it "returns nil for blank key" do
      expect(described_class.find_valid_token("")).to be_nil
      expect(described_class.find_valid_token(nil)).to be_nil
    end

    it "returns nil for non-existent token" do
      expect(described_class.find_valid_token("nonexistent")).to be_nil
    end

    it "returns nil for expired token" do
      token.update!(expires_on: 1.day.ago)
      expect(described_class.find_valid_token(token.plain_value)).to be_nil
    end

    it "returns nil for inactive user" do
      user.update!(status: User.statuses[:locked])
      expect(described_class.find_valid_token(token.plain_value)).to be_nil
    end

    it "returns nil for deleted user" do
      # Create a new user and token for this test
      test_user = create(:user)
      test_token = described_class.create(user: test_user)

      # Delete the token first, then the user
      test_token.destroy
      test_user.destroy

      # The token should no longer exist
      expect(described_class.find_valid_token(test_token.plain_value)).to be_nil
    end
  end

  describe "expiration" do
    it "is not expired when created" do
      token = described_class.create(user:)
      expect(token.expired?).to be false
    end

    it "is expired when expires_on is in the past" do
      token = described_class.create(user:)
      token.update!(expires_on: 1.day.ago)
      expect(token.expired?).to be true
    end

    it "uses validity_time for expiration calculation" do
      allow(described_class).to receive(:validity_time).and_return(7.days)
      token = described_class.create(user:)

      expect(token.expires_on).to be_within(1.second).of(7.days.from_now)
    end
  end

  describe "associations" do
    it "belongs to a user" do
      token = described_class.create(user:)
      expect(token.user).to eq(user)
    end

    it "can have multiple autologin session links" do
      token = described_class.create(user:)

      # Create SqlBypass sessions first
      sql_session1 = create(:user_session, user:)
      sql_session2 = create(:user_session, user:)

      # Get the corresponding UserSession records
      session1 = Sessions::UserSession.find_by(session_id: sql_session1.session_id)
      session2 = Sessions::UserSession.find_by(session_id: sql_session2.session_id)

      link1 = Sessions::AutologinSessionLink.create(token:, session: session1)
      link2 = Sessions::AutologinSessionLink.create(token:, session: session2)

      expect(token.autologin_session_links).to include(link1, link2)
    end
  end

  describe "deletion behavior" do
    it "deletes associated session links when token is destroyed" do
      token = described_class.create(user:)

      # Create SqlBypass session first
      sql_session = create(:user_session, user:)

      # Get the corresponding UserSession record
      session = Sessions::UserSession.find_by(session_id: sql_session.session_id)
      link = Sessions::AutologinSessionLink.create(token:, session:)

      expect { token.destroy }.to change(Sessions::AutologinSessionLink, :count).by(-1)
      expect { link.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
