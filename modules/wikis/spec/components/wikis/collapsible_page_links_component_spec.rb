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

RSpec.describe Wikis::CollapsiblePageLinksComponent, type: :component do
  let(:project) { create(:project) }
  let(:work_package) { create(:work_package, project:) }
  let(:provider) { create(:internal_wiki_provider) }
  let(:heading) { "Referenced in" }
  let(:page_info) do
    Wikis::Adapters::Results::PageInfo.new(
      identifier: "MyPage",
      title: "My Wiki Page",
      provider:,
      href: "https://wiki.example.com/MyPage"
    )
  end
  let(:page_info_result) { Success(page_info) }
  let(:already_related_page_keys) { Set.new }
  let(:permissions) { [:manage_wiki_page_links] }
  let(:view_model) { Wikis::PageLinkViewModel.from_page_info_result(page_info_result) }
  let(:page_links) { [view_model] }

  current_user { create(:user, member_with_permissions: { project => permissions }) }

  subject(:rendered_component) do
    render_inline(
      described_class.new(page_links,
                          heading:,
                          container: :inline_page_links,
                          linkable: work_package,
                          already_related_page_keys:)
    )
  end

  before { rendered_component }

  it_behaves_like "rendering Box", row_count: 1

  it "renders the heading and the page link" do
    expect(page).to have_text(heading)
    expect(page).to have_link(text: page_info.title, href: page_info.href)
  end

  it "renders a collapsible header with the heading and item count", :aggregate_failures do
    expect(page).to have_css("collapsible-header")
    expect(page).to have_css(".Box-header") do |header|
      expect(header).to have_heading(heading)
      expect(header).to have_css(".Counter", text: "1")
    end
  end

  context "without page links" do
    let(:page_links) { [] }

    it "still renders the collapsible header with a hidden zero count", :aggregate_failures do
      expect(page).to have_css("collapsible-header")
      expect(page).to have_css(".Box-header") do |header|
        expect(header).to have_heading(heading)
        expect(header).to have_css(".Counter[hidden]", text: "0", visible: :all)
      end
    end
  end

  context "when the user may manage wiki page links" do
    it "offers to add the page to the related pages" do
      expect(page).to have_test_selector("wiki-page-link-action-menu")
      expect(page).to have_link(text: "Add to related pages")
    end

    context "when the page is already a related page" do
      let(:already_related_page_keys) { Set[[provider.id, page_info.identifier]] }

      it "disables the action" do
        expect(page).to have_css("[aria-disabled='true']", text: "Add to related pages")
        expect(page).to have_no_link(text: "Add to related pages")
      end
    end
  end

  context "when the user may not manage wiki page links" do
    let(:permissions) { [] }

    it "does not render the action menu" do
      expect(page).not_to have_test_selector("wiki-page-link-action-menu")
    end
  end

  context "when the page info could not be resolved" do
    let(:page_info_result) do
      Failure(
        SimpleError.new(
          source: Wikis::Adapters::Providers::Internal::Queries::PageInfo,
          code: :not_found
        )
      )
    end

    it "renders the error and no action menu" do
      expect(page).to have_text(I18n.t("wikis.page_links.errors.page_not_found"))
      expect(page).not_to have_test_selector("wiki-page-link-action-menu")
    end
  end
end
