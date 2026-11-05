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

RSpec.describe SquashTMIntegration::ConnectionCheck do
  let(:client) { instance_double(SquashTMIntegration::Client) }
  let(:errors) { ActiveModel::Errors.new(SquashTMIntegration::Server.new) }

  subject(:check) { described_class.new(base_url: "https://squashtm.example.com/squash", api_token: "token").call(errors) }

  before do
    allow(SquashTMIntegration::Client).to receive(:new).and_return(client)
    allow(client).to receive(:version).and_return("15.0.2.RELEASE")
  end

  it "adds no errors when SquashTM answers" do
    allow(client).to receive(:projects).and_return({})

    check

    expect(errors).to be_empty
  end

  describe "version check" do
    before { allow(client).to receive(:projects).and_return({}) }

    %w[15.0.2.RELEASE 15.0.3.RELEASE 15.1.0 16.0.0.RELEASE].each do |version|
      it "accepts #{version}" do
        allow(client).to receive(:version).and_return(version)

        check

        expect(errors).to be_empty
      end
    end

    it "rejects a version below the minimum" do
      allow(client).to receive(:version).and_return("14.2.0.RELEASE")

      check

      expect(errors.details[:base])
        .to eq([{ error: :squashtm_version_unsupported, version: "14.2.0", minimum: Gem::Version.new("15.0.2") }])
      expect(errors.full_messages).to eq(["The SquashTM server runs version 14.2.0, but version 15.0.2 or newer is required."])
    end

    it "rejects a server that does not report its version" do
      allow(client).to receive(:version).and_raise(SquashTMIntegration::Client::NotFoundError.new(404))

      check

      expect(errors.details[:base].pluck(:error)).to eq([:squashtm_version_unsupported])
      expect(errors.details[:base].first[:version]).to eq("unknown")
    end

    it "rejects an unparseable version" do
      allow(client).to receive(:version).and_return("snapshot")

      check

      expect(errors.details[:base].first).to include(error: :squashtm_version_unsupported, version: "unknown")
    end
  end

  {
    SsrfError: %i[base base_url_ssrf_filtered],
    TimeoutError: %i[base base_url_request_timed_out],
    SslError: %i[base base_url_ssl_error],
    InvalidUrlError: %i[base base_url_invalid],
    ConnectionError: %i[base base_url_cannot_be_connected_to],
    InvalidResponseError: %i[base base_url_not_squashtm]
  }.each do |error_class, (attribute, error_type)|
    it "reports a #{error_class} as #{attribute} #{error_type}" do
      allow(client).to receive(:projects).and_raise(SquashTMIntegration::Client.const_get(error_class))

      check

      expect(errors.details[attribute].pluck(:error)).to eq([error_type])
    end
  end

  {
    NotFoundError: 404,
    UnexpectedStatusError: 400
  }.each do |error_class, status|
    it "reports a #{error_class} (HTTP #{status}) as not answering like a SquashTM server" do
      allow(client).to receive(:projects).and_raise(SquashTMIntegration::Client.const_get(error_class).new(status))

      check

      expect(errors.details[:base].pluck(:error)).to eq([:base_url_not_squashtm])
    end
  end

  it "reports an AuthenticationError as api_token rejected" do
    allow(client).to receive(:projects).and_raise(SquashTMIntegration::Client::AuthenticationError.new(401))

    check

    expect(errors.details[:base].pluck(:error)).to eq([:api_token_rejected])
  end

  it "reports a ServerError with the URL and status" do
    allow(client).to receive(:projects).and_raise(SquashTMIntegration::Client::ServerError.new(502))

    check

    expect(errors.details[:base]).to eq(
      [{ error: :base_url_server_error, url: "https://squashtm.example.com/squash", status: 502 }]
    )
    expect(errors.full_messages).to eq(
      ["The SquashTM server at https://squashtm.example.com/squash responded with an error (HTTP 502). " \
       "Please ensure it is running and healthy."]
    )
  end
end
