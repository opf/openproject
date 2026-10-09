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

RSpec.describe Token::API do
  let(:user) { create(:user) }

  describe "expiry scopes" do
    let!(:never_expiring) { create(:api_token, user:) }
    let!(:valid_until_tomorrow) { create(:api_token, user:, expires_on: 1.day.from_now) }
    let!(:expired) { create(:api_token, user:).tap { it.update_column(:expires_on, 1.day.ago) } }

    it ".expired returns tokens whose expiry has passed" do
      expect(described_class.expired).to contain_exactly(expired)
    end

    it ".not_expired returns tokens without expiry or with a future expiry" do
      expect(described_class.not_expired).to contain_exactly(never_expiring, valid_until_tomorrow)
    end
  end

  describe "#expired?" do
    subject(:token) { build(:api_token, user:, expires_on:) }

    context "without an expiry" do
      let(:expires_on) { nil }

      it { is_expected.not_to be_expired }
    end

    context "with a future expiry" do
      let(:expires_on) { 1.minute.from_now }

      it { is_expected.not_to be_expired }
    end

    context "with a past expiry" do
      let(:expires_on) { 1.minute.ago }

      it { is_expected.to be_expired }
    end
  end

  describe "#expires_on_date" do
    let(:user) { build(:user, preferences: { time_zone: "Europe/Berlin" }) }
    let(:berlin) { Time.find_zone("Europe/Berlin") }

    subject(:token) { build(:api_token, user:) }

    it "sets expires_on to the end of that day in the user's time zone" do
      token.expires_on_date = "2026-10-12"

      expect(token.expires_on).to eq(berlin.local(2026, 10, 12).end_of_day)
    end

    it "accepts a Date" do
      token.expires_on_date = Date.new(2026, 10, 12)

      expect(token.expires_on).to eq(berlin.local(2026, 10, 12).end_of_day)
    end

    it "clears the expiry when blank" do
      token.expires_on = 1.day.from_now
      token.expires_on_date = ""

      expect(token.expires_on).to be_nil
    end

    it "reads back the date in the user's time zone" do
      token.expires_on = berlin.local(2026, 10, 12).end_of_day

      expect(token.expires_on_date).to eq(Date.new(2026, 10, 12))
    end

    it "accepts today" do
      token.expires_on_date = berlin.today.iso8601

      expect(token).to be_valid
    end

    it "rejects an invalid date" do
      token.expires_on_date = "2026-13-45"

      expect(token).not_to be_valid
      expect(token.errors.symbols_for(:expires_on)).to contain_exactly(:not_a_date)
    end
  end

  describe "#valid_plaintext?" do
    subject(:token) { create(:api_token, user:) }

    it "accepts the plain value of a token that has not expired" do
      expect(token.valid_plaintext?(token.plain_value)).to be true
    end

    it "rejects the plain value of an expired token" do
      token.update_column(:expires_on, 1.minute.ago)

      expect(token.valid_plaintext?(token.plain_value)).to be false
    end
  end

  describe "expires_on validation" do
    it "accepts no expiry" do
      expect(build(:api_token, user:, expires_on: nil)).to be_valid
    end

    it "accepts a future expiry" do
      expect(build(:api_token, user:, expires_on: 1.minute.from_now)).to be_valid
    end

    it "rejects a past expiry" do
      token = build(:api_token, user:, expires_on: 1.minute.ago)

      expect(token).not_to be_valid
      expect(token.errors.symbols_for(:expires_on)).to contain_exactly(:datetime_must_be_in_future)
    end

    it "keeps an already expired token valid when other attributes change" do
      token = create(:api_token, user:)
      token.update_column(:expires_on, 1.day.ago)

      token.token_name = "renamed"

      expect(token).to be_valid
    end
  end
end
