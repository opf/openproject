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

RSpec.describe Documents::OAuth::DecryptTokenService,
               with_settings: { collaborative_editing_hocuspocus_secret: "test_secret_for_encryption" } do
  subject(:service_call) { described_class.new(token:).call }

  let(:plaintext) { { resource_url: "http://example.com/api/v3/documents/1", oauth_token: "abc" }.to_json }
  let(:encrypted) { Documents::OAuth::EncryptTokenService.new(token: plaintext).call.result }

  describe "#call" do
    context "with a token encrypted by the EncryptTokenService" do
      let(:token) { encrypted }

      it "returns the decrypted payload" do
        expect(service_call).to be_success
        expect(service_call.result).to eq(plaintext)
      end
    end

    context "with a tampered token" do
      let(:token) do
        data, iv, auth_tag = encrypted.split("--")
        tampered = Base64.strict_encode64(Base64.strict_decode64(data).reverse)
        [tampered, iv, auth_tag].join("--")
      end

      it "fails" do
        expect(service_call).to be_failure
      end
    end

    context "with garbage" do
      let(:token) { "not-an-encrypted-token" }

      it "fails" do
        expect(service_call).to be_failure
      end
    end

    context "with a nil token" do
      let(:token) { nil }

      it "fails" do
        expect(service_call).to be_failure
      end
    end

    context "with a token encrypted with another secret" do
      let(:token) { encrypted }

      before do
        token
        allow(Setting).to receive(:collaborative_editing_hocuspocus_secret).and_return("another_secret")
      end

      it "fails" do
        expect(service_call).to be_failure
      end
    end

    context "when the secret is not set" do
      let(:token) { encrypted }

      before do
        token
        allow(Setting).to receive(:collaborative_editing_hocuspocus_secret).and_return(nil)
      end

      it "fails" do
        expect(service_call).to be_failure
      end
    end
  end
end
