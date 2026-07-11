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

require "services/base_services/behaves_like_create_service"

RSpec.describe Wikis::XWikiProviders::CreateService, type: :model do
  it_behaves_like "BaseServices create service" do
    let(:factory) { :xwiki_provider }
    let(:call_attributes) { { name: "My XWiki", url: "https://xwiki.example.com" } }
    let!(:model_instance) { build_stubbed(factory, name: "My XWiki", url: "https://xwiki.example.com") }

    before do
      allow(Wikis::XWikiProviders::FetchInstanceIdService).to receive(:new)
        .and_return(instance_double(Wikis::XWikiProviders::FetchInstanceIdService, call: Dry::Monads::Success("test-id")))
    end
  end

  describe "instance id fetching" do
    subject(:result) { service.call(**call_attributes) }

    let(:call_attributes) { { name: "My XWiki", url: "https://xwiki.example.com" } }
    let(:current_user) { build_stubbed(:admin) }
    let(:service) { described_class.new(user: current_user) }
    let(:fetch_service) { instance_double(Wikis::XWikiProviders::FetchInstanceIdService, call: fetch_result) }
    let(:fetch_result) { Success("xwiki-instance-abc123") }

    before do
      allow(Wikis::XWikiProviders::FetchInstanceIdService).to receive(:new).and_return(fetch_service)
    end

    it "stores the universal_identifier" do
      expect(result).to be_success
      expect(result.result.universal_identifier).to eq("xwiki-instance-abc123")
    end

    it "fetches the universal identifier immediately" do
      subject
      expect(fetch_service).to have_received(:call)
    end

    it "enqueues no job to update the universal identifier" do
      expect { subject }.not_to have_enqueued_job(Wikis::XWikiProviders::FetchInstanceIdJob)
    end

    context "when XWiki is unreachable" do
      let(:fetch_result) { Failure(:connection_error) }

      it "fails with a url error" do
        expect(result).not_to be_success
        expect(result.errors[:url]).to include("could not be reached.")
      end
    end

    context "when wiki provider is configured from environment", with_settings: { wiki_providers: [{ "name" => "My XWiki" }] } do
      let(:service) { described_class.new(user: current_user, contract_class: Wikis::XWikiProviders::EnvironmentCreateContract) }

      it "does not fetch the universal identifier immediately" do
        subject
        expect(fetch_service).not_to have_received(:call)
      end

      it "enqueues a job to update the universal identifier" do
        expect { subject }.to have_enqueued_job(Wikis::XWikiProviders::FetchInstanceIdJob)
      end

      context "and when the universal identifier was explicitly set" do
        let(:call_attributes) { { name: "My XWiki", url: "https://xwiki.example.com", universal_identifier: "the-uid" } }

        it "persists the given identifier" do
          expect(result).to be_success
          expect(result.result.universal_identifier).to eq("the-uid")
        end

        it "does not fetch the universal identifier immediately" do
          subject
          expect(fetch_service).not_to have_received(:call)
        end

        it "enqueues no job to update the universal identifier" do
          expect { subject }.not_to have_enqueued_job(Wikis::XWikiProviders::FetchInstanceIdJob)
        end
      end
    end
  end
end
