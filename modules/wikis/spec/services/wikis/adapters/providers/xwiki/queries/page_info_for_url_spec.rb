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

RSpec.describe Wikis::Adapters::Providers::XWiki::Queries::PageInfoForUrl,
               with_settings: { host_name: "openproject.example.com" } do
  subject { described_class.new(model: provider).call(input_data:, auth_strategy:) }

  let(:provider) { create(:xwiki_provider, :with_connected_user, connected_user: user, url: "https://xwiki.example.com/") }
  let(:input_data) { Wikis::Adapters::Input::PageInfoForUrl.build(url:).value! }
  let(:auth_strategy) { provider.auth_strategy_for(user).value! }

  let(:user) { create(:user) }
  let(:canonical_page_info_query) do
    instance_double(
      Wikis::Adapters::Providers::XWiki::Queries::Internal::CanonicalPageInfo,
      call: Failure(Wikis::Adapters::Results::Error.new(source: self, code: :not_found))
    )
  end

  before do
    allow(Wikis::Adapters::Providers::XWiki::Queries::Internal::CanonicalPageInfo)
      .to receive(:new).and_return(canonical_page_info_query)
  end

  shared_examples_for "successfully resolves" do |identifier|
    let(:success_result) { Success("The result for #{identifier}") }

    before do
      allow(canonical_page_info_query).to receive(:call) do |input_data:, **|
        if input_data.identifier == identifier
          success_result
        else
          Failure(
            # misusing #source a bit to allow for better spec-failure output
            Wikis::Adapters::Results::Error.new(code: :not_found, source: "Unexpected identifier #{input_data.identifier}")
          )
        end
      end
    end

    it "returns the result of the page_info query" do
      expect(subject).to eq(success_result)
    end

    it "passes the correct auth strategy along to the page_info query" do
      subject

      expect(canonical_page_info_query).to have_received(:call).with(input_data: anything, auth_strategy:).at_least(:once)
    end
  end

  context "for a default wiki URL to a space" do
    let(:url) { "https://xwiki.example.com/bin/view/Sandbox" }

    it_behaves_like "successfully resolves", "xwiki:Sandbox.WebHome"
  end

  context "for a default wiki URL to a page" do
    let(:url) { "https://xwiki.example.com/bin/view/Sandbox/TestPage1" }

    it_behaves_like "successfully resolves", "xwiki:Sandbox.TestPage1"
  end

  context "for a default wiki URL to a space with trailing slash" do
    let(:url) { "https://xwiki.example.com/bin/view/Sandbox/" }

    it_behaves_like "successfully resolves", "xwiki:Sandbox.WebHome"
  end

  context "for a default wiki URL to a page with trailing slash" do
    let(:url) { "https://xwiki.example.com/bin/view/Sandbox/TestPage1/" }

    it_behaves_like "successfully resolves", "xwiki:Sandbox.TestPage1"
  end

  context "for a default wiki URL to a nested space" do
    let(:url) { "https://xwiki.example.com/bin/view/Sandbox/Subspace" }

    it_behaves_like "successfully resolves", "xwiki:Sandbox.Subspace.WebHome"
  end

  context "when linking to edit view of a wiki page" do
    let(:url) { "https://xwiki.example.com/bin/view/Sandbox/#edit" }

    it_behaves_like "successfully resolves", "xwiki:Sandbox.WebHome"
  end

  context "for a secondary wiki URL to a space" do
    let(:url) { "https://xwiki.example.com/wiki/otherwiki/view/Sandbox" }

    it_behaves_like "successfully resolves", "otherwiki:Sandbox.WebHome"
  end

  context "for a secondary wiki URL to a page" do
    let(:url) { "https://xwiki.example.com/wiki/otherwiki/view/Sandbox/TestPage1" }

    it_behaves_like "successfully resolves", "otherwiki:Sandbox.TestPage1"
  end

  context "for a secondary wiki URL to a nested space" do
    let(:url) { "https://xwiki.example.com/wiki/otherwiki/view/Sandbox/Subspace" }

    it_behaves_like "successfully resolves", "otherwiki:Sandbox.Subspace.WebHome"
  end

  context "when the URL contains URL-encoded characters" do
    let(:url) { "https://xwiki.example.com/bin/view/Test%20Page/" }

    it_behaves_like "successfully resolves", "xwiki:Test Page.WebHome"
  end

  context "when URL has the wrong hostname" do
    let(:url) { "https://otherwiki.example.com/bin/view/Sandbox" }

    it { is_expected.to be_failure }
  end

  context "when linking to something else than a wiki page" do
    let(:url) { "https://xwiki.example.com/bin/admin/XWiki/XWikiPreferences" }

    it { is_expected.to be_failure }
  end
end
