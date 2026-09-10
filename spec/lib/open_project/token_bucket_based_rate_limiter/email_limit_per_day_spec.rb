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

RSpec.describe OpenProject::TokenBucketBasedRateLimiter::EmailLimitPerDay do
  context "when a limit is configured", with_settings: { email_limit_per_day: 24 } do
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
      let(:state) { TokenBucketState.find_by!(identifier: :email_limit_per_day) }

      it { is_expected.to be true }

      context "with tokens available" do
        before do
          # Full bucket
          state.update!(microtokens: 24_000_000, refilled_at: Time.current)
        end

        it { is_expected.to be true }

        it "removes tokens from the state" do
          consume!

          expect(state.reload.microtokens).to eq 23_000_000
        end
      end
    end
  end

  context "when no limit is configured" do
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
      let(:state) { TokenBucketState.find_by!(identifier: :email_limit_per_day) }

      it { is_expected.to be true }

      context "with no tokens to consume" do
        before do
          state.update!(microtokens: 0, refilled_at: Time.current)
        end

        it { is_expected.to be true }
      end
    end
  end
end
