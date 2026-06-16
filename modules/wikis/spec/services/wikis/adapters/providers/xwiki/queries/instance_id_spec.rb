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

RSpec.describe Wikis::Adapters::Providers::XWiki::Queries::InstanceId, :disable_ssrf_filter, :webmock do
  it "is registered" do
    expect(Wikis::Adapters::Registry.resolve("xwiki.queries.instance_id")).to eq(described_class)
  end

  describe "#call" do
    let(:user) { create(:user) }
    let(:wiki_provider) { create(:xwiki_provider, :for_local_connection, connected_user: user) }
    let(:metadata_url) { "https://xwiki.local/rest/openproject/metadata" }
    let(:auth_strategy) { Wikis::Adapters::Input::AuthStrategy.build(key: :noop).value! }

    subject(:result) { described_class.new(model: wiki_provider).call(auth_strategy:) }

    context "when the request succeeds", vcr: "xwiki/instance_id" do
      # Recorded against a real XWiki instance (spec/support/fixtures/vcr_cassettes/xwiki/instance_id.yml);
      # instanceId was scrubbed. To re-record: delete the cassette and run with VCR_RECORD_MODE=new_episodes.
      let(:expected_instance_id) { "xwiki-instance-abc123" }

      it "returns Success with the instance id" do
        expect(result).to be_success
        expect(result.value!).to eq(expected_instance_id)
      end
    end

    context "when no OAuth token exists for the user" do
      let(:wiki_provider) { create(:xwiki_provider, :with_oauth_client, url: "https://xwiki.local/") }
      let(:auth_strategy) { wiki_provider.auth_strategy_for(user).value! }

      it { is_expected.to be_failure.and have_attributes(failure: have_attributes(code: :missing_token)) }
    end

    context "when access is unauthorized" do
      before { stub_request(:get, metadata_url).to_return(status: 401, body: "") }

      it { is_expected.to be_failure.and have_attributes(failure: have_attributes(code: :unauthorized)) }
    end

    context "when XWiki returns a non-2xx status" do
      before { stub_request(:get, metadata_url).to_return(status: 500, body: "Internal Server Error") }

      it { is_expected.to be_failure.and have_attributes(failure: have_attributes(code: :request_failed)) }
    end

    context "when a network error occurs" do
      before { stub_request(:get, metadata_url).to_timeout }

      it { is_expected.to be_failure.and have_attributes(failure: have_attributes(code: :connection_error)) }
    end

    context "when the response body is not valid JSON" do
      before do
        stub_request(:get, metadata_url)
          .to_return(status: 200, body: "not json", headers: { "Content-Type" => "application/json" })
      end

      it { is_expected.to be_failure.and have_attributes(failure: have_attributes(code: :invalid_response)) }
    end

    context "when the response is missing the instanceId field" do
      before do
        stub_request(:get, metadata_url)
          .to_return(status: 200, body: {}.to_json, headers: { "Content-Type" => "application/json" })
      end

      it { is_expected.to be_failure.and have_attributes(failure: have_attributes(code: :invalid_response)) }
    end
  end
end
