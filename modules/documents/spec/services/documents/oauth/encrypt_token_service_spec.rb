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

RSpec.describe Documents::OAuth::EncryptTokenService do
  subject(:service_call) { described_class.new(token:).call }

  before do
    allow(Setting)
      .to receive(:collaborative_editing_hocuspocus_secret)
      .and_return(secret)
  end

  describe "#call" do
    context "when the secret is not defined" do
      let(:secret) { nil }
      let(:token) { "anything" }

      it "return an failure" do
        result = service_call
        expect(result).to be_failure
      end
    end

    context "when the secret is short" do
      let(:secret) { "short_secret" }
      let(:token) { "sensitive_token_value" }

      it "returns a successful result with the encrypted token" do
        result = service_call
        expect(result).to be_success

        encrypted_token = result.result

        expect(encrypted_token).not_to eq(token)
        expect(encrypted_token).to be_a(String)
        expect(encrypted_token.length).to be > token.length
      end
    end

    context "when the secret is long" do
      let(:secret) { "this_is_a_very_long_and_secure_secret_for_encryption_purposes_123456" }
      let(:token) { "sensitive_token_value" }

      it "returns a success result with the encrypted token" do
        result = service_call
        expect(result).to be_success

        encrypted_token = result.result

        expect(encrypted_token).not_to eq(token)
        expect(encrypted_token).to be_a(String)
        expect(encrypted_token.length).to be > token.length
      end
    end
  end
end
