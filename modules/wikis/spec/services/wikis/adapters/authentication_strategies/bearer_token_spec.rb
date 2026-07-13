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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require_module_spec_helper

RSpec.describe Wikis::Adapters::AuthenticationStrategies::BearerToken, :webmock do
  let(:url) { "https://xwiki.local/rest/" }
  let(:user) { build_stubbed(:user) }
  let(:oauth_client) { build_stubbed(:oauth_client) }
  let(:provider) { instance_double(Wikis::XWikiProvider, oauth_client:) }
  let(:oauth_client_token) { instance_double(OAuthClientToken, access_token: "test-token") }

  subject(:strategy) { described_class.new(user, provider) }

  before do
    allow(OAuthClientToken).to receive(:for_user_and_client).with(user, oauth_client)
      .and_return(instance_double(ActiveRecord::Relation, first: oauth_client_token))
  end

  describe "#call" do
    it "yields an http client configured with the bearer token" do
      request_stub = stub_request(:get, url)
        .with(headers: { "Authorization" => "Bearer test-token" })
        .to_return(status: 200, body: "")

      strategy.call { |http| http.get(url) }

      expect(request_stub).to have_been_requested
    end

    it "forwards http_options to the http client" do
      request_stub = stub_request(:get, url)
        .with(headers: { "Authorization" => "Bearer test-token", "Accept" => "application/json" })
        .to_return(status: 200, body: "")

      strategy.call(http_options: { headers: { "Accept" => "application/json" } }) { |http| http.get(url) }

      expect(request_stub).to have_been_requested
    end

    context "when no OAuth token exists for the user" do
      let(:oauth_client_token) { nil }

      it "returns a missing_token failure without yielding" do
        expect { |b| strategy.call(&b) }.not_to yield_control

        result = strategy.call { raise "should not be called" }
        expect(result).to be_failure
        expect(result.failure.code).to eq(:missing_token)
      end
    end
  end
end
