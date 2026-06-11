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

RSpec.describe Wikis::XWikiProviders::SetAttributesService, :webmock, type: :model do
  let(:current_user) { build_stubbed(:admin) }
  let(:model) { Wikis::XWikiProvider.new }
  let(:service) do
    described_class.new(
      user: current_user,
      model:,
      contract_class: Wikis::XWikiProviders::CreateContract
    )
  end

  describe "#call" do
    context "when the URL is set or changed" do
      context "and XWiki responds successfully" do
        context "on a new provider", vcr: "xwiki/instance_id" do
          it "fetches and stores the universal_identifier" do
            service.call(url: "https://xwiki.local/", name: "My Wiki")
            expect(model.universal_identifier).to eq("xwiki-instance-abc123")
          end
        end

        context "when the URL changes", vcr: "xwiki/instance_id" do
          let(:model) { create(:xwiki_provider, url: "https://old.example.com/", universal_identifier: "old-id") }

          it "re-fetches and updates the universal_identifier" do
            service.call(url: "https://xwiki.local/")
            expect(model.universal_identifier).to eq("xwiki-instance-abc123")
          end
        end
      end

      context "and XWiki is unreachable" do
        let(:metadata_url) { "https://xwiki.local/rest/openproject/metadata" }

        subject(:result) { service.call(url: "https://xwiki.local/", name: "My Wiki") }

        context "when XWiki returns a non-2xx response" do
          before { stub_request(:get, metadata_url).to_return(status: 500, body: "Internal Server Error") }

          it { is_expected.to be_success }
          it { expect(result && model.universal_identifier).to be_nil }
        end

        context "when a network error occurs" do
          before { stub_request(:get, metadata_url).to_timeout }

          it { is_expected.to be_success }
          it { expect(result && model.universal_identifier).to be_nil }
        end
      end
    end

    context "when no fetch is needed" do
      let(:query_spy) { instance_spy(Wikis::Adapters::Providers::XWiki::Queries::InstanceId) }

      before do
        allow(Wikis::Adapters::Providers::XWiki::Queries::InstanceId).to receive(:new).and_return(query_spy)
      end

      it "skips the query when no URL is provided" do
        service.call(name: "My Wiki")
        expect(query_spy).not_to have_received(:call)
      end

      context "when the URL is unchanged" do
        let(:model) { create(:xwiki_provider, url: "https://xwiki.local/", universal_identifier: "existing-id") }

        it "skips the query and preserves the universal_identifier" do
          service.call(name: "Renamed Wiki")
          expect(query_spy).not_to have_received(:call)
          expect(model.universal_identifier).to eq("existing-id")
        end
      end
    end
  end
end
