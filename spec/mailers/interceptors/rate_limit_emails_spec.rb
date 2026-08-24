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

RSpec.describe Interceptors::RateLimitEmails do
  let(:to) { ["john@example.com"] }
  let(:cc) { nil }
  let(:bcc) { nil }
  let(:mail) do
    Mail.new({ from: "noreply@example.net", to:, cc:, bcc:, subject: "Notification", body: "Hi" }.compact)
  end

  let(:token_bucket_state) { TokenBucketState.with_instance(:email_limit_per_day) { it } }

  def intercept!
    described_class.delivering_email(mail)
  end

  context "when a limit is configured", with_settings: { email_limit_per_day: 10 } do
    context "with no tokens to consume" do
      before do
        token_bucket_state.update!(microtokens: 0, refilled_at: Time.current)
      end

      it "drops the mail" do
        intercept!

        expect(mail.perform_deliveries).to be false
      end
    end

    context "with tokens to consume" do
      before do
        token_bucket_state.update!(microtokens: 10 * 1_000_000, refilled_at: Time.current)
      end

      context "and one recipient" do
        let(:to) { ["joe@example.org"] }

        it "removes one token from the bucket" do
          intercept!

          expect(token_bucket_state.reload.microtokens).to eq(9 * 1_000_000)
        end

        it "keeps the mail" do
          intercept!

          expect(mail.perform_deliveries).to be true
        end
      end

      context "and four recipients" do
        let(:to) { ["joe@example.org", "jane@example.org"] }
        let(:cc) { ["jim@example.org"] }
        let(:bcc) { ["janet@example.org"] }

        it "removes four tokens from the bucket" do
          intercept!

          expect(token_bucket_state.reload.microtokens).to eq(6 * 1_000_000)
        end

        it "keeps the mail" do
          intercept!

          expect(mail.perform_deliveries).to be true
        end
      end

      context "and duplicate recipients" do
        let(:to) { ["joe@example.org"] }
        let(:cc) { ["joe@example.org"] }
        let(:bcc) { ["joe@example.org"] }

        it "removes just one token per uniq recipient from the bucket" do
          intercept!

          expect(token_bucket_state.reload.microtokens).to eq(9 * 1_000_000)
        end

        it "keeps the mail" do
          intercept!

          expect(mail.perform_deliveries).to be true
        end
      end
    end
  end

  context "when NO limit is configured", with_settings: { email_limit_per_day: 0 } do
    context "with no tokens to consume" do
      before do
        token_bucket_state.update!(microtokens: 0, refilled_at: Time.current)
      end

      it "still doesn't drop the mail" do
        intercept!

        expect(mail.perform_deliveries).to be true
      end
    end
  end
end
