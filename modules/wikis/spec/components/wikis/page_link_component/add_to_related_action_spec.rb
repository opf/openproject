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

RSpec.describe Wikis::PageLinkComponent::AddToRelatedAction do
  let(:work_package) { build_stubbed(:work_package) }
  let(:provider) { build_stubbed(:internal_wiki_provider) }
  let(:page_info) do
    Wikis::Adapters::Results::PageInfo.new(
      identifier: "MyPage",
      title: "My Wiki Page",
      provider:,
      href: "https://wiki.example.com/MyPage"
    )
  end
  let(:url_helpers) { Rails.application.routes.url_helpers }
  let(:already_related) { false }

  subject(:action) do
    described_class.new(page_info:, linkable: work_package, url_helpers:, already_related:)
  end

  it "uses the plus icon" do
    expect(action.icon).to eq(:plus)
  end

  it "builds a menu item posting to the relation page link creation" do
    expect(action.menu_item_args).to include(
      label: I18n.t("wikis.page_link_component.add_to_related_pages"),
      tag: :a,
      href: url_helpers.relation_wiki_page_links_path(
        wikis_relation_page_link: {
          provider_id: provider.id,
          linkable_type: "WorkPackage",
          linkable_id: work_package.id
        },
        identifier: page_info.identifier
      ),
      content_arguments: { data: { turbo_method: :post } }
    )
  end

  context "when the page is already related" do
    let(:already_related) { true }

    it "builds an inert disabled menu item without an href" do
      expect(action.menu_item_args).to eq(
        label: I18n.t("wikis.page_link_component.add_to_related_pages"),
        disabled: true
      )
    end
  end
end
