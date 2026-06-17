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

require "services/base_services/behaves_like_update_service"

RSpec.describe Wikis::XWikiProviders::UpdateService, type: :model do
  it_behaves_like "BaseServices update service" do
    let(:factory) { :xwiki_provider }
    let(:call_attributes) { { name: "Updated XWiki" } }
    let!(:model_instance) { build_stubbed(factory, name: "My XWiki", url: "https://xwiki.example.com") }
  end

  describe "#call" do
    let(:current_user) { build_stubbed(:admin) }
    let(:provider) { create(:xwiki_provider, url: "https://old.example.com/", universal_identifier: "old-id") }
    let(:service) { described_class.new(user: current_user, model: provider) }
    let(:fetch_service) { instance_spy(Wikis::XWikiProviders::FetchInstanceIdService) }

    before do
      allow(Wikis::XWikiProviders::FetchInstanceIdService).to receive(:new).and_return(fetch_service)
    end

    context "when the URL changes" do
      before { allow(fetch_service).to receive(:call).and_return(Dry::Monads::Success("xwiki-instance-abc123")) }

      it "re-fetches and updates the universal_identifier" do
        result = service.call(url: "https://xwiki.local/")
        expect(result).to be_success
        expect(result.result.universal_identifier).to eq("xwiki-instance-abc123")
      end
    end

    context "when the URL is unchanged" do
      it "skips the fetch and preserves the universal_identifier" do
        result = service.call(name: "Renamed Wiki")
        expect(result).to be_success
        expect(fetch_service).not_to have_received(:call)
        expect(result.result.universal_identifier).to eq("old-id")
      end
    end

    context "when XWiki is unreachable" do
      before { allow(fetch_service).to receive(:call).and_return(Dry::Monads::Failure(:connection_error)) }

      it "fails with a url error" do
        result = service.call(url: "https://xwiki.local/")
        expect(result).not_to be_success
        expect(result.errors[:url]).to include("could not be reached.")
      end
    end
  end
end
