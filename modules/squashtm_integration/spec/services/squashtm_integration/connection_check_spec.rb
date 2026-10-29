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
  end

  it "adds no errors when SquashTM answers" do
    allow(client).to receive(:projects).and_return({})

    check

    expect(errors).to be_empty
  end

  {
    SsrfError: %i[base_url ssrf_filtered],
    TimeoutError: %i[base_url request_timed_out],
    SslError: %i[base_url ssl_error],
    InvalidUrlError: %i[base_url invalid_url],
    ConnectionError: %i[base_url cannot_be_connected_to],
    AuthenticationError: %i[api_token rejected],
    ResponseError: %i[base_url not_squashtm]
  }.each do |error_class, (attribute, error_type)|
    it "reports a #{error_class} as #{attribute} #{error_type}" do
      allow(client).to receive(:projects).and_raise(SquashTMIntegration::Client.const_get(error_class))

      check

      expect(errors.details[attribute].pluck(:error)).to eq([error_type])
    end
  end

  it "reports a ServerError as base_url server_error with the status" do
    allow(client).to receive(:projects).and_raise(SquashTMIntegration::Client::ServerError.new(502))

    check

    expect(errors.details[:base_url]).to eq([{ error: :server_error, status: 502 }])
    expect(errors.full_messages).to eq(
      ["SquashTM URL responded with an error (HTTP 502). Please ensure the SquashTM server is running and healthy."]
    )
  end
end
