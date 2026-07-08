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

RSpec.describe Wikis::Adapters::Providers::XWiki::Queries::CanonicalPageHierarchy, :disable_ssrf_filter, :webmock do
  it "is not registered" do
    expect { Wikis::Adapters::Registry.resolve("xwiki.queries.page_hierarchy") }
      .to raise_error Wikis::Adapters::Registry::OperationNotSupported
  end

  describe "#call" do
    subject(:result) { described_class.new(model: provider).call(input_data:, auth_strategy:) }

    let(:user) { create(:user) }
    let(:provider) { create(:xwiki_provider, :for_local_connection, connected_user: user) }
    let(:identifier) { "xwiki:VCR.Incredible space.Ümlæûts.WebHome" }
    let(:auth_strategy) { provider.auth_strategy_for(user).value! }
    let(:input_data) { Wikis::Adapters::Input::PageHierarchy.build(identifier:).value! }

    context "when the page exists", vcr: "xwiki/canonical_page_hierarchy" do
      it { is_expected.to be_success }

      it "returns the page matching the requested identifier" do
        page = subject.value!.page
        expect(page.identifier).to eq("a2290")
        expect(page.provider).to eq(provider)
        expect(page.title).to eq("Ümlæûts")
        expect(page.href).to eq("https://xwiki.local/bin/view/VCR/Incredible%20space/%C3%9Cml%C3%A6%C3%BBts/")
      end

      it "returns the wiki the requested page belongs to" do
        wiki_data = subject.value!.wiki
        expect(wiki_data.identifier).to eq("xwiki")
        expect(wiki_data.provider).to eq(provider)
        expect(wiki_data.name).to eq("xwiki")
        expect(wiki_data.href).to eq("https://xwiki.local/bin/view/Main/")
      end

      it "returns the ancestors of the requested page" do
        ancestors = subject.value!.ancestors
        expect(ancestors.size).to eq(2)
        expect(ancestors[0].identifier).to eq("0db76")
        expect(ancestors[0].title).to eq("Incredible space")
        expect(ancestors[1].identifier).to eq("dc27c")
        expect(ancestors[1].title).to eq("VCR")
      end
    end

    context "when the identifier is not a valid XWiki reference" do
      let(:identifier) { "Main.WebHome" }

      it { is_expected.to be_failure.and have_attributes(failure: have_attributes(code: :not_found)) }
    end

    context "when no OAuth token exists for the user" do
      let(:provider) { create(:xwiki_provider, :with_oauth_client, url: "https://xwiki.local/") }

      it { is_expected.to be_failure.and have_attributes(failure: have_attributes(code: :missing_token)) }
    end

    context "when the page is not found", vcr: "xwiki/canonical_page_hierarchy_not_found" do
      let(:identifier) { "xwiki:VCR.Incredible no space.Ümlæûts.WebHome" }

      it { is_expected.to be_failure.and have_attributes(failure: have_attributes(code: :not_found)) }
    end
  end
end
