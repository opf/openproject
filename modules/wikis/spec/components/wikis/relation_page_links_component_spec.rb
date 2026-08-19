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

RSpec.describe Wikis::RelationPageLinksComponent, type: :component do
  let(:user) { create(:user) }
  let(:work_package) { build_stubbed(:work_package) }
  let(:provider) { create(:xwiki_provider) }
  let(:oauth_client) { create(:oauth_client, integration: provider) }

  let(:page_link_service) { instance_double(Wikis::PageLinkService, relation_page_links_for: []) }

  subject(:render_component) { render_inline(described_class.new(provider, work_package:)) }

  before do
    login_as(user)
    allow(Wikis::PageLinkService).to receive(:new).and_return(page_link_service)
  end

  context "when the provider has no oauth client configured" do
    before do
      allow(provider).to receive(:oauth_client).and_return(nil)
      render_component
    end

    it { expect(page).to have_text(I18n.t("wikis.relation_page_links_component.empty_heading")) }
    it { expect(page).to have_no_text(I18n.t("wikis.oauth_login_component.heading", provider: provider.name)) }
  end

  context "when the provider does not support OAuth" do
    let(:provider) { create(:internal_wiki_provider) }

    before { render_component }

    it { expect(page).to have_text(I18n.t("wikis.relation_page_links_component.empty_heading")) }
    it { expect(page).to have_text(I18n.t("wikis.relation_page_links_component.empty_text")) }
    it { expect(page).to have_no_text(I18n.t("wikis.oauth_login_component.heading", provider: provider.name)) }
  end

  context "when the provider has an oauth client but the user has no token" do
    before do
      allow(provider).to receive(:oauth_client).and_return(oauth_client)
      render_component
    end

    it { expect(page).to have_text(I18n.t("wikis.oauth_login_component.heading", provider: provider.name)) }
  end

  context "when the user has a token for the provider" do
    before do
      allow(provider).to receive(:oauth_client).and_return(oauth_client)
      create(:oauth_client_token, oauth_client:, user:)
      render_component
    end

    it { expect(page).to have_text(I18n.t("wikis.relation_page_links_component.empty_heading")) }
    it { expect(page).to have_no_text(I18n.t("wikis.oauth_login_component.heading", provider: provider.name)) }
  end

  context "when the user has a token and there are page links" do
    let(:page_link) { create(:relation_wiki_page_link, provider:, linkable: work_package) }
    let(:page_info) do
      Wikis::Adapters::Results::PageInfo.new(
        identifier: "MyPage",
        title: "My Wiki Page",
        href: "https://wiki.example.com/MyPage",
        provider:
      )
    end
    let(:page_link_aggregate) do
      Wikis::Adapters::Results::PageLinkAggregate.new(page_link:, page_info_result: Dry::Monads::Success(page_info))
    end

    before do
      allow(provider).to receive(:user_connected?).and_return(true)
      allow(page_link_service).to receive(:relation_page_links_for).and_return([page_link_aggregate])
      render_component
    end

    it { expect(page).to have_text("My Wiki Page") }
    it { expect(page).to have_no_text(I18n.t("wikis.relation_page_links_component.empty_heading")) }
    it { expect(page).to have_no_text(I18n.t("wikis.oauth_login_component.heading", provider: provider.name)) }
  end
end
