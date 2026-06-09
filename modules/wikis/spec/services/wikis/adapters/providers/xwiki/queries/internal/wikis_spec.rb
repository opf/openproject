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

RSpec.describe Wikis::Adapters::Providers::XWiki::Queries::Internal::Wikis, :webmock do
  include XWikiStubs

  describe "#call" do
    let(:user) { create(:user) }
    let(:wiki_provider) do
      create(:xwiki_provider, :with_connected_user, url: "https://xwiki.example.com/", connected_user: user)
    end
    let(:auth_strategy) do
      Wikis::Adapters::Input::AuthStrategy.build(key: :bearer_token, user:, provider: wiki_provider).value!
    end
    let(:query) { described_class.new(model: wiki_provider) }

    subject(:result) { query.call(auth_strategy:) }

    context "when the farm has multiple wikis" do
      before { stub_wiki_list(%w[xwiki myfarm], provider: wiki_provider) }

      it { is_expected.to be_success }

      it "returns the list of wiki IDs" do
        expect(result.value!).to contain_exactly("xwiki", "myfarm")
      end
    end

    context "when the response has no wikis" do
      before { stub_wiki_list([], provider: wiki_provider) }

      it { is_expected.to be_success }

      it "returns an empty list" do
        expect(result.value!).to eq([])
      end
    end

    context "when access is unauthorized" do
      before { stub_request(:get, wikis_endpoint(wiki_provider)).to_return(status: 401, body: "") }

      it { is_expected.to be_failure.and have_attributes(failure: have_attributes(code: :unauthorized)) }
    end

    context "when access is forbidden" do
      before { stub_request(:get, wikis_endpoint(wiki_provider)).to_return(status: 403, body: "") }

      it { is_expected.to be_failure.and have_attributes(failure: have_attributes(code: :unauthorized)) }
    end

    context "when XWiki returns a non-2xx status" do
      before { stub_request(:get, wikis_endpoint(wiki_provider)).to_return(status: 500, body: "Internal Server Error") }

      it { is_expected.to be_failure.and have_attributes(failure: have_attributes(code: :request_failed)) }
    end

    context "when a network error occurs" do
      before { stub_request(:get, wikis_endpoint(wiki_provider)).to_timeout }

      it { is_expected.to be_failure.and have_attributes(failure: have_attributes(code: :connection_error)) }
    end

    context "when the response body is not valid JSON" do
      before do
        stub_request(:get, wikis_endpoint(wiki_provider))
          .to_return(status: 200, body: "not json", headers: { "Content-Type" => "application/json" })
      end

      it { is_expected.to be_failure.and have_attributes(failure: have_attributes(code: :invalid_response)) }
    end
  end
end
