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

RSpec.describe Wikis::Adapters::Providers::XWiki::Queries::User, :webmock do
  let(:user) { build_stubbed(:user) }
  let(:oauth_client) { build_stubbed(:oauth_client) }
  let(:wiki_provider) { build_stubbed(:xwiki_provider, url: "https://xwiki.local/") }
  let(:root_url) { "https://xwiki.local/rest/" }
  let(:auth_strategy) { Wikis::Adapters::Input::AuthStrategy.build(key: :bearer_token, user:, provider: wiki_provider).value! }

  subject(:query) { described_class.new(model: wiki_provider) }

  before do
    allow(wiki_provider).to receive(:oauth_client).and_return(oauth_client)
    allow(OAuthClientToken).to receive(:for_user_and_client).with(user, oauth_client)
      .and_return(instance_double(ActiveRecord::Relation, first: instance_double(OAuthClientToken, access_token: "some-token")))
  end

  it "is registered" do
    expect(Wikis::Adapters::Registry.resolve("xwiki.queries.user")).to eq(described_class)
  end

  describe "#call" do
    context "when the request succeeds with an xwiki-user header" do
      before do
        stub_request(:get, root_url)
          .with(headers: { "Authorization" => "Bearer some-token" })
          .to_return(status: 200, body: "", headers: { "xwiki-user" => "XWiki.admin" })
      end

      it "returns Success with the xwiki-user header value" do
        result = query.call(auth_strategy:)
        expect(result).to be_success
        expect(result.value!).to eq("XWiki.admin")
      end
    end

    context "when the response is missing the xwiki-user header" do
      before do
        stub_request(:get, root_url)
          .to_return(status: 200, body: "")
      end

      it "returns Failure with :unauthorized code" do
        result = query.call(auth_strategy:)
        expect(result).to be_failure
        expect(result.failure).to have_attributes(code: :unauthorized)
      end
    end

    context "when XWiki returns a non-2xx status" do
      before do
        stub_request(:get, root_url).to_return(status: 401, body: "Unauthorized")
      end

      it "returns Failure with :request_failed code" do
        result = query.call(auth_strategy:)
        expect(result).to be_failure
        expect(result.failure).to have_attributes(code: :request_failed)
      end
    end

    context "when a network error occurs" do
      before { stub_request(:get, root_url).to_timeout }

      it "returns Failure with :connection_error code" do
        result = query.call(auth_strategy:)
        expect(result).to be_failure
        expect(result.failure).to have_attributes(code: :connection_error)
      end
    end
  end
end
