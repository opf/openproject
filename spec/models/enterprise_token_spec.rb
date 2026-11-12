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

RSpec.describe EnterpriseToken do
  include EnterpriseTokenFactory

  describe ".active?" do
    context "without any tokens" do
      it "returns false" do
        expect(described_class.active?).to be(false)
      end
    end

    context "with a non expired token" do
      before do
        create_enterprise_token("an_non_expired_token", expires_at: 1.year.from_now)
      end

      it "returns true" do
        expect(described_class.active?).to be(true)
      end
    end

    context "with an expired token" do
      before do
        create_enterprise_token(subject.encoded_token, expires_at: Date.yesterday)
      end

      it "returns false" do
        expect(described_class.active?).to be(false)
      end
    end

    context "with two tokens: one expired and one active" do
      before do
        # expired token
        create_enterprise_token("an_expired_token", expires_at: Date.yesterday)

        # active token
        create_enterprise_token("an_active_token", expires_at: 1.year.from_now)
      end

      it "returns true" do
        expect(described_class.active?).to be(true)
      end
    end
  end

  describe ".hide_banners?" do
    context "when ee_hide_banners is true",
            with_config: { ee_hide_banners: true } do
      it "returns true" do
        expect(described_class).to be_hide_banners
      end
    end

    context "when ee_hide_banners is false",
            with_config: { ee_hide_banners: false } do
      it "returns false" do
        expect(described_class).not_to be_hide_banners
      end
    end
  end

  describe ".user_limit" do
    context "without any tokens" do
      it "returns `nil` (unlimited)" do
        expect(described_class.user_limit).to be_nil
      end
    end

    context "when only trial tokens exist" do
      before do
        create_enterprise_token("trial_token_10_users", trial: true,
                                                        restrictions: { active_user_count: 10 })
        create_enterprise_token("trial_token_20_users", trial: true,
                                                        restrictions: { active_user_count: 20 })
        create_enterprise_token("trial_token_30_users_expired", trial: true,
                                                                restrictions: { active_user_count: 30 },
                                                                expires_at: Date.yesterday)
        create_enterprise_token("trial_token_40_users_invalid", trial: true,
                                                                restrictions: { active_user_count: 40 },
                                                                domain: "invalid.domain")
      end

      it "returns the maximum seats value of active trial tokens" do
        expect(described_class.user_limit).to eq(20)
      end

      it "returns `nil` (unlimited) if an active trial token has no seats limit" do
        create_enterprise_token("trial_token_unlimited_users", trial: true)
        expect(described_class.user_limit).to be_nil
      end
    end

    context "when trial and non-trial tokens exist" do
      before do
        create_enterprise_token("non_trial_token_10_users", restrictions: { active_user_count: 10 })
        create_enterprise_token("trial_token_50_users", trial: true,
                                                        restrictions: { active_user_count: 50 })
        create_enterprise_token("non_trial_token_20_users", restrictions: { active_user_count: 20 })
      end

      it "ignores trial tokens and returns the maximum seats value of active non-trial tokens" do
        expect(described_class.user_limit).to eq(20)
      end

      it "returns `nil` (unlimited) if an active non-trial token has no seats limit" do
        # unlimited token not taken into account: trial
        create_enterprise_token("trial_token_unlimited_users", trial: true)
        expect(described_class.user_limit).to eq(20)

        # unlimited token not taken into account: invalid domain
        create_enterprise_token("non_trial_token_unlimited_users_invalid", domain: "invalid.domain")
        expect(described_class.user_limit).to eq(20)

        # unlimited token not taken into account: expired
        create_enterprise_token("non_trial_token_unlimited_users_expired", expires_at: Date.yesterday)
        expect(described_class.user_limit).to eq(20)

        # valid unlimited token
        create_enterprise_token("non_trial_token_unlimited_users")
        expect(described_class.user_limit).to be_nil
      end
    end
  end

  context "with an existing token" do
    context "when inner token is active" do
      subject! do
        mock_token_object(
          "an_active_token_object",
          subscriber: "foo",
          mail: "bar@example.com",
          starts_at: Date.current,
          issued_at: Date.current,
          expires_at: nil,
          restrictions: { foo: :bar }
        )
        described_class.create!(encoded_token: "an_active_token_object")
      end

      it "is returned by .active_tokens" do
        expect(described_class.count).to eq(1)
        expect(described_class.active_tokens).to eq([subject])
        active_token = described_class.active_tokens.first
        expect(active_token.encoded_token).to eq("an_active_token_object")

        # Deleting it updates the active tokens list
        active_token.destroy!

        expect(described_class.count).to eq(0)
        expect(described_class.active_tokens).to be_empty
      end

      it "delegates calls to the inner token object" do
        expect(subject.subscriber).to eq("foo")
        expect(subject.mail).to eq("bar@example.com")
        expect(subject.starts_at).to eq(Date.current)
        expect(subject.issued_at).to eq(Date.current)
        expect(subject.expires_at).to be_nil
        expect(subject.restrictions).to eq(foo: :bar)
      end

      describe "#allows_to?" do
        let(:service_double) { Authorization::EnterpriseService.new(subject) }

        before do
          allow(Authorization::EnterpriseService)
            .to receive(:new)
            .with(subject)
            .and_return(service_double)
        end

        it "forwards to EnterpriseTokenService for checks" do
          allow(service_double)
            .to receive(:call)
            .with(:forbidden_action)
            .and_return ServiceResult.success(result: false)
          allow(service_double)
            .to receive(:call)
            .with(:allowed_action)
            .and_return ServiceResult.success(result: true)

          expect(described_class.allows_to?(:forbidden_action)).to be false
          expect(described_class.allows_to?(:allowed_action)).to be true
        end
      end
    end

    context "when updated with an invalid token" do
      subject! { create_enterprise_token("an_active_token_object", expires_at: 1.year.from_now) }

      it "fails validations" do
        expect { subject.encoded_token = "bar" }
          .to change(subject, :valid?).from(true).to(false)
      end
    end
  end

  describe ".all_tokens" do
    it "returns all tokens, ordered from oldest expiration date to latest (non expiring ones are last)" do
      create_enterprise_token("a_token_expired_recently", expires_at: Date.yesterday)
      create_enterprise_token("a_token_expiring_soon", expires_at: Date.tomorrow)
      create_enterprise_token("a_token_without_an_expiration_date", expires_at: nil)
      create_enterprise_token("a_token_expired_since_one_year", expires_at: Date.current - 1.year)
      create_enterprise_token("a_token_expiring_in_one_year", expires_at: Date.current + 1.year)

      expect(described_class.all_tokens.map(&:encoded_token))
        .to eq(%w[
                 a_token_expired_since_one_year
                 a_token_expired_recently
                 a_token_expiring_soon
                 a_token_expiring_in_one_year
                 a_token_without_an_expiration_date
               ])
    end

    it "sorts by token start date if multiple tokens have the same expiration date" do
      create_enterprise_token("a_token_started_one_week_ago", starts_at: Date.current - 1.week, expires_at: Date.current + 1.year)
      create_enterprise_token("a_token_starting_in_one_week", starts_at: Date.current + 1.week, expires_at: Date.current + 1.year)
      create_enterprise_token("a_token_started_one_year_ago", starts_at: Date.current - 1.year, expires_at: Date.current + 1.year)
      create_enterprise_token("a_non_expiring_token_starting_in_one_month", starts_at: Date.current + 1.month, expires_at: nil)
      create_enterprise_token("a_non_expiring_token_started_today", starts_at: Date.current, expires_at: nil)
      create_enterprise_token("a_non_expiring_token_started_one_month_ago", starts_at: Date.current - 1.month, expires_at: nil)

      expect(described_class.all_tokens.map(&:encoded_token))
        .to eq(%w[
                 a_token_started_one_year_ago
                 a_token_started_one_week_ago
                 a_token_starting_in_one_week
                 a_non_expiring_token_started_one_month_ago
                 a_non_expiring_token_started_today
                 a_non_expiring_token_starting_in_one_month
               ])
    end
  end

  describe ".active_tokens" do
    context "with no tokens" do
      it "returns an empty array" do
        expect(described_class.active_tokens).to be_empty
      end
    end

    context "with a token that has not started yet" do
      let!(:future_token) { create_enterprise_token("a_future_token", starts_at: 1.month.from_now) }

      it "does not return the future token" do
        expect(described_class.active_tokens).to be_empty
      end
    end

    context "with an active token" do
      let!(:active_token) { create_enterprise_token("an_active_token", expires_at: 1.year.from_now) }

      it "returns the active token" do
        expect(described_class.active_tokens).to eq([active_token])
      end
    end

    context "with a trial token" do
      let!(:trial_token) { create_enterprise_token("a_trial_token", trial: true, expires_at: 1.year.from_now) }

      it "returns the trial token" do
        expect(described_class.active_tokens).to eq([trial_token])
      end
    end

    context "with expired and invalid tokens" do
      let!(:expired_token) { create_enterprise_token("an_expired_token", expires_at: Date.yesterday) }
      let!(:expired_trial_token) { create_enterprise_token("an_expired_trial_token", trial: true, expires_at: Date.yesterday) }
      let!(:invalid_token) { create_enterprise_token("an_invalid_token_with_wrong_domain", domain: "wrong.domain") }

      it "returns an empty array" do
        expect(described_class.active_tokens).to be_empty
      end
    end

    context "when the user messed with the database to 'extend' their validity" do
      let!(:expired_token) { create_enterprise_token("an_active_token", expires_at: 1.day.ago) }

      before do
        expired_token.update_column(:valid_until, 1.year.from_now)
      end

      it "returns an empty array" do
        expect(described_class.active_tokens).to be_empty
      end
    end
  end

  describe ".active" do
    it "builds the correct query with today if no date is provided" do
      travel_to("2025-01-01T12:00:00Z") do
        expect(described_class.active.to_sql).to include(<<~SQL.squish)
          WHERE ((valid_from IS NULL OR valid_from <= '2025-01-01')
          AND
          (valid_until IS NULL OR valid_until >= '2025-01-01'))
        SQL
      end
    end

    it "builds the correct query with the given date" do
      expect(described_class.active(Date.parse("2026-06-01")).to_sql).to include(<<~SQL.squish)
        WHERE ((valid_from IS NULL OR valid_from <= '2026-06-01')
        AND
        (valid_until IS NULL OR valid_until >= '2026-06-01'))
      SQL
    end

    it "is consistent with #active?" do
      combinations = [nil, Date.yesterday, Date.current, Date.tomorrow]
        .then { |dates| dates.product(dates) }
      combinations.each do |starts_at, expires_at|
        described_class.delete_all
        token = create_enterprise_token(starts_at:, expires_at:)
        if token.active?
          expect(described_class.active).to include(token), "Expected .active to have returned active token #{token.inspect}"
        else
          expect(described_class.active).to be_empty, "Expected .active to have NOT returned inactive token #{token.inspect}"
        end
      end
    end
  end

  describe ".available_features" do
    context "with no tokens" do
      it "returns an empty array" do
        expect(described_class.available_features).to be_empty
      end
    end

    context "with an active token" do
      let!(:active_token) { create_enterprise_token("an_active_token", plan: :basic, expires_at: 1.year.from_now) }

      it "returns the features for the plan of the token" do
        expect(described_class.available_features).to match_array(OpenProject::Token::FEATURES_PER_PLAN[:basic])
      end
    end

    context "with a trial token" do
      let!(:trial_token) { create_enterprise_token("a_trial_token", plan: :basic, trial: true, expires_at: 1.year.from_now) }

      it "returns the features for the plan of the token" do
        expect(described_class.available_features).to match_array(OpenProject::Token::FEATURES_PER_PLAN[:basic])
      end
    end

    context "with expired and invalid tokens" do
      let!(:expired_token) { create_enterprise_token("an_expired_token", plan: :basic, expires_at: Date.yesterday) }
      let!(:expired_trial_token) do
        create_enterprise_token("an_expired_trial_token", plan: :basic, trial: true, expires_at: Date.yesterday)
      end
      let!(:invalid_token) { create_enterprise_token("an_invalid_token_with_wrong_domain", plan: :basic, domain: "wrong.domain") }

      it "returns an empty array" do
        expect(described_class.available_features).to be_empty
      end
    end
  end

  describe ".trialling?(feature)" do
    # basic < professional < premium < corporate
    let(:basic_plan_feature) { OpenProject::Token::BASIC_PLAN_FEATURES.first }
    let(:professional_plan_feature) { OpenProject::Token::PROFESSIONAL_PLAN_FEATURES.first }
    let(:premium_plan_feature) { OpenProject::Token::PREMIUM_PLAN_FEATURES.first }
    let(:corporate_plan_feature) { OpenProject::Token::CORPORATE_PLAN_FEATURES.first }

    context "with no tokens" do
      it "returns false" do
        expect(described_class.trialling?(basic_plan_feature)).to be false
        expect(described_class.trialling?(premium_plan_feature)).to be false
      end
    end

    context "with only an active non-trial token" do
      let!(:token) { create_enterprise_token(plan: :basic) }

      it "returns false" do
        expect(described_class.trialling?(basic_plan_feature)).to be false
        expect(described_class.trialling?(premium_plan_feature)).to be false
      end
    end

    context "with only a trial token" do
      let!(:trial_token) { create_enterprise_token(plan: :basic, trial: true) }

      it "returns true for features included in the token plan" do
        expect(described_class.trialling?(basic_plan_feature)).to be true
        expect(described_class.trialling?(premium_plan_feature)).to be false
      end
    end

    context "with a basic non-trial token and a premium trial token" do
      let!(:token) { create_enterprise_token("a_token_for_basic_plan", plan: :basic) }
      let!(:trial_token) { create_enterprise_token("a_trial_token_for_premium_plan", plan: :premium, trial: true) }

      it "returns false for features included in non-trial plan and true for features only included in trial plan" do
        expect(described_class.trialling?(basic_plan_feature)).to be false
        expect(described_class.trialling?(professional_plan_feature)).to be true
        expect(described_class.trialling?(premium_plan_feature)).to be true
        expect(described_class.trialling?(corporate_plan_feature)).to be false
      end
    end

    context "with a premium non-trial token and a basic trial token" do
      let!(:token) { create_enterprise_token("a_token_for_premium_plan", plan: :premium) }
      let!(:trial_token) { create_enterprise_token("a_trial_token_for_basic_plan", plan: :basic, trial: true) }

      it "returns false for any features as trial basic features are included in non-trial premium plan" do
        expect(described_class.trialling?(basic_plan_feature)).to be false
        expect(described_class.trialling?(professional_plan_feature)).to be false
        expect(described_class.trialling?(premium_plan_feature)).to be false
        expect(described_class.trialling?(corporate_plan_feature)).to be false
      end
    end

    context "with expired and invalid tokens" do
      let!(:expired_trial_token) do
        create_enterprise_token("an_expired_trial_token", plan: :premium, trial: true, expires_at: Date.yesterday)
      end
      let!(:invalid_trial_token) do
        create_enterprise_token("an_invalid_trial_token_with_wrong_domain", plan: :basic, trial: true, domain: "wrong.domain")
      end

      it "returns an empty array" do
        expect(described_class.trialling?(basic_plan_feature)).to be false
        expect(described_class.trialling?(professional_plan_feature)).to be false
        expect(described_class.trialling?(premium_plan_feature)).to be false
        expect(described_class.trialling?(corporate_plan_feature)).to be false
      end
    end
  end

  context "when Configuration file has `ee_hide_banners` set to false",
          with_config: { ee_hide_banners: false } do
    it "shows banners promoting Enterprise plans" do
      expect(described_class).not_to be_hide_banners
    end
  end

  describe "#max_active_users" do
    context "when token restrictions is nil" do
      let(:token) { build_enterprise_token(restrictions: nil) }

      it "returns nil" do
        expect(token.max_active_users).to be_nil
      end
    end

    context "when token restrictions does not have an active_user_count key" do
      let(:token) { build_enterprise_token(restrictions: { foo: :bar }) }

      it "returns nil" do
        expect(token.max_active_users).to be_nil
      end
    end

    context "when token restrictions has an active_user_count key" do
      let(:token) { build_enterprise_token(restrictions: { active_user_count: 10 }) }

      it "returns the active_user_count value" do
        expect(token.max_active_users).to eq(10)
      end
    end
  end

  describe "#unlimited_users?" do
    context "when token restrictions is nil" do
      let(:token) { build_enterprise_token(restrictions: nil) }

      it "is true" do
        expect(token.unlimited_users?).to be true
      end
    end

    context "when token restrictions does not have an active_user_count key" do
      let(:token) { build_enterprise_token(restrictions: { foo: :bar }) }

      it "is true" do
        expect(token.unlimited_users?).to be true
      end
    end

    context "when token restrictions has an active_user_count key" do
      let(:token) { build_enterprise_token(restrictions: { active_user_count: 10 }) }

      it "is false" do
        expect(token.unlimited_users?).to be false
      end
    end
  end

  describe "#expiring_soon?" do
    context "when token expiration date is within 30 days" do
      it "returns true" do
        expect(build_enterprise_token(expires_at: Date.current)).to be_expiring_soon
        expect(build_enterprise_token(expires_at: Date.current.next_day(10))).to be_expiring_soon
        expect(build_enterprise_token(expires_at: Date.current.next_day(30))).to be_expiring_soon
      end
    end

    context "when token has no expiration date" do
      it "returns false" do
        expect(build_enterprise_token(expires_at: nil)).not_to be_expiring_soon
      end
    end

    context "when token expiration date is within 30 days but token is not active yet" do
      it "returns false" do
        expect(build_enterprise_token(starts_at: Date.tomorrow, expires_at: Date.current.next_day(20))).not_to be_expiring_soon
      end
    end

    context "when token is expired but in grace period" do
      it "returns false" do
        expect(build_enterprise_token(expires_at: Date.yesterday, reprieve_days: 1)).not_to be_expiring_soon
      end
    end

    context "when token is expired" do
      it "returns false" do
        expect(build_enterprise_token(expires_at: Date.current.prev_day(10), reprieve_days: 5)).not_to be_expiring_soon
      end
    end
  end

  describe "#in_grace_period?" do
    context "when token has no expiration date" do
      it "returns false" do
        expect(build_enterprise_token(expires_at: nil)).not_to be_in_grace_period
      end
    end

    context "when token expiration date is today or in the future" do
      it "returns false" do
        expect(build_enterprise_token(expires_at: Date.current, reprieve_days: 100)).not_to be_in_grace_period
        expect(build_enterprise_token(expires_at: Date.tomorrow, reprieve_days: 100)).not_to be_in_grace_period
      end
    end

    context "when token expiration date is in the past within reprieve_days days" do
      it "returns true" do
        expect(build_enterprise_token(expires_at: Date.yesterday, reprieve_days: 1)).to be_in_grace_period
        expect(build_enterprise_token(expires_at: Date.current.prev_day(10), reprieve_days: 10)).to be_in_grace_period
        expect(build_enterprise_token(expires_at: Date.current.prev_day(10), reprieve_days: 20)).to be_in_grace_period
      end
    end

    context "when token expiration date is in the past outside of reprieve_days days" do
      it "returns false" do
        expect(build_enterprise_token(expires_at: Date.yesterday, reprieve_days: 0)).not_to be_in_grace_period
        expect(build_enterprise_token(expires_at: Date.current.prev_day(10), reprieve_days: 9)).not_to be_in_grace_period
      end
    end
  end

  describe "#expired?" do
    context "when token has no expiration date" do
      let(:token) { build_enterprise_token(expires_at: nil) }

      it "is not expired" do
        expect(token).not_to be_expired
      end
    end

    context "when token is invalid" do
      let(:token) { build_enterprise_token(domain: "wrong.domain") }

      it "is not expired" do
        expect(token).not_to be_expired
      end
    end

    context "when token expiration date is in the past" do
      let(:token) { build_enterprise_token(expires_at: Date.yesterday) }

      it "is expired" do
        expect(token).to be_expired
      end
    end

    context "when token expiration date is today" do
      let(:token) { build_enterprise_token(expires_at: Date.current) }

      it "is not expired" do
        expect(token).not_to be_expired
      end
    end

    context "when token expiration date is in the future" do
      let(:token) { build_enterprise_token(expires_at: Date.tomorrow) }

      it "is not expired" do
        expect(token).not_to be_expired
      end
    end
  end

  describe "extract validity from token" do
    let(:starts_at) { Date.parse("2025-01-01") }
    let(:expires_at) { Date.parse("2025-01-31") }
    let(:reprieve_days) { 0 }

    let!(:token) do
      create_enterprise_token(plan: :basic, starts_at: starts_at, expires_at: expires_at, reprieve_days: reprieve_days)
    end

    context "without a starts_at date" do
      let(:starts_at) { nil }

      it "extracts the dates" do
        expect(token.valid_from).to be_nil
        expect(token.valid_until).to eq(expires_at)
      end
    end

    context "with a starts_at date & expires_at date without reprieve_days" do
      let(:reprieve_days) { 0 }

      it "extracts the dates" do
        expect(token.valid_from).to eq(starts_at)
        expect(token.valid_until).to eq(expires_at)
      end
    end

    context "with a starts_at date & expires_at date with reprieve_days" do
      let(:reprieve_days) { 5 }

      it "extracts the dates" do
        expect(token.valid_from).to eq(starts_at)
        expect(token.valid_until).to eq(expires_at + reprieve_days.days)
      end
    end
  end
end
