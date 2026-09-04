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

RSpec.describe OpenProject::TokenBucketBasedRateLimiter::Base, freeze_time: Time.current.change(usec: 0) do
  let!(:token_bucket_state) { create(:token_bucket_state, identifier: :sample, microtokens:, refilled_at:) }
  let(:microtokens) { 0 }
  let(:refilled_at) { Time.current }

  context "when a limit is configured" do
    let(:described_class) do
      Class.new(OpenProject::TokenBucketBasedRateLimiter::Base) do
        def limit
          24
        end

        def identifier
          :sample
        end
      end
    end

    describe "enabled?" do
      subject(:enabled?) { described_class.enabled? }

      it { is_expected.to be true }
    end

    describe "limit" do
      subject(:limit) { described_class.limit }

      it { is_expected.to eq 24 }
    end

    describe "consume!" do
      subject(:consume!) { described_class.consume!(tokens) }

      let(:tokens) { 1 }

      context "with no tokens to consume" do
        let(:microtokens) { 0 }

        it { is_expected.to be false }
      end

      context "with tokens available" do
        let(:microtokens) { 24_000_000 }

        it { is_expected.to be true }

        it "removes tokens from the state" do
          consume!

          expect(token_bucket_state.reload.microtokens).to eq 23_000_000
        end
      end

      context "when tokens need refilling" do
        let(:tokens) { 2 }

        # 1 token left, but 2 tokens have been aquired in the mean time
        let(:microtokens) { 1_000_000 }
        let(:refilled_at) { 2.hours.ago }

        it { is_expected.to be true }

        it "refills and consumes tokens" do
          consume!

          expect(token_bucket_state.reload.microtokens).to eq 1_000_000
        end
      end

      context "when too many tokens are to be consumed" do
        let(:tokens) { 2 }

        # 1 token left
        let(:microtokens) { 1_000_000 }

        it { is_expected.to be false }

        it "does not consume tokens" do
          consume!

          expect(token_bucket_state.reload.microtokens).to eq 1_000_000
        end
      end
    end
  end

  context "when limit is set to 0" do
    let(:described_class) do
      Class.new(OpenProject::TokenBucketBasedRateLimiter::Base) do
        def limit
          0
        end

        def identifier
          :sample
        end
      end
    end

    describe "enabled?" do
      subject(:enabled?) { described_class.enabled? }

      it { is_expected.to be false }
    end

    describe "limit" do
      subject(:limit) { described_class.limit }

      it { is_expected.to eq 0 }
    end

    describe "consume!" do
      subject(:consume!) { described_class.consume!(tokens) }

      let(:tokens) { 1 }

      context "with no tokens to consume" do
        let(:microtokens) { 0 }

        it { is_expected.to be true }
      end

      context "with tokens available" do
        let(:microtokens) { 1_234_567_890 }

        it { is_expected.to be true }

        it "doesn't remove tokens from the state" do
          consume!

          expect(token_bucket_state.reload.microtokens).to eq 1_234_567_890
        end
      end
    end
  end
end
