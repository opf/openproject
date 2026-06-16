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

module Wikis
  RSpec.describe CreateLinkedPageService do
    include Dry::Monads[:result]

    subject(:service_result) do
      described_class.new(provider:, user:).call(
        title:,
        parent_identifier:,
        linkable_type: linkable.class.name,
        linkable_id: linkable.id
      )
    end

    let(:user) { build_stubbed(:user) }
    let(:linkable) { build_stubbed(:work_package) }
    let(:title) { "My Page" }
    let(:parent_identifier) { "MySpace.Parent" }
    let(:page_identifier) { "#{parent_identifier}.MyPage" }
    let(:provider) { instance_double(Provider, id: 1) }
    let(:auth_strategy) { instance_double(Adapters::AuthenticationStrategies::BearerToken) }
    let(:create_page_command) { instance_double(Adapters::Providers::XWiki::Commands::CreatePage) }
    let(:page_info) do
      Adapters::Results::PageInfo.new(identifier: page_identifier, title:,
                                      href: "https://wiki.example.com/MyPage", provider:)
    end
    let(:page_link) { build_stubbed(:relation_wiki_page_link) }
    let(:create_link_service) { instance_double(RelationPageLinks::CreateService) }
    let(:create_link_result) { ServiceResult.success(result: page_link) }

    before do
      allow(provider).to receive(:auth_strategy_for).with(user).and_return(Success(auth_strategy))
      allow(provider).to receive(:resolve).with("commands.create_page").and_return(create_page_command)
      allow(create_page_command).to receive(:call)
        .with(input_data: anything, auth_strategy: auth_strategy)
        .and_return(Success(page_info))
      allow(RelationPageLinks::CreateService).to receive(:new).with(user:).and_return(create_link_service)
      allow(create_link_service).to receive(:call).and_return(create_link_result)
    end

    context "when all steps succeed" do
      it "returns a successful service result" do
        expect(service_result).to be_success
      end

      it "returns the created page link as the result" do
        expect(service_result.result).to eq(page_link)
      end

      it "creates a page link with the page identifier from the command result" do
        service_result

        expect(create_link_service).to have_received(:call).with(
          provider_id: provider.id,
          linkable_type: linkable.class.name,
          linkable_id: linkable.id,
          author_id: user.id,
          identifier: page_identifier
        )
      end
    end

    context "when the create link service fails" do
      let(:create_link_result) { ServiceResult.failure }

      it "returns the failure" do
        expect(service_result).to eq(create_link_result)
      end
    end

    context "when auth strategy fails" do
      before do
        allow(provider).to receive(:auth_strategy_for).with(user)
          .and_return(Failure(Adapters::Results::Error.new(source: self, code: :missing_token)))
      end

      it "returns a failure service result with the auth error code" do
        expect(service_result).to be_failure
        expect(service_result.errors.where(:base).map(&:type)).to include(:missing_token)
      end
    end

    context "when the create page command fails" do
      let(:command_error) { Adapters::Results::Error.new(source: Adapters::Providers::XWiki::Commands::CreatePage, code: :not_found) }

      before do
        allow(create_page_command).to receive(:call).and_return(Failure(command_error))
      end

      it "returns a failure service result" do
        expect(service_result).to be_failure
      end

      it "adds the command error code to the wiki_page attribute" do
        expect(service_result.errors.where(:wiki_page).map(&:type)).to include(:not_found)
      end
    end
  end
end
