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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require_module_spec_helper

RSpec.describe Wikis::WorkPackageWikisTabComponent, type: :component do
  let(:provider) { build_stubbed(:xwiki_provider) }
  let(:work_package) { build_stubbed(:work_package) }
  let(:inline_page_links) { [] }
  let(:referencing_wiki_pages) { [] }

  let(:page_link_service) do
    instance_double(
      Wikis::PageLinkService,
      inline_page_link_infos_for: inline_page_links,
      referencing_wiki_page_references_for: referencing_wiki_pages,
      relation_page_link_keys_for: Set.new
    )
  end

  def page_info_result(title)
    Dry::Monads::Success(
      Wikis::Adapters::Results::PageInfo.new(
        identifier: title,
        title:,
        href: "https://wiki.example.com/#{title}",
        provider:
      )
    )
  end

  def page_reference_result(title, source: :mention)
    page_info_result(title).fmap do |page_info|
      Wikis::Adapters::Results::PageReference.new(page_info:, source:)
    end
  end

  subject(:render_component) { render_inline(described_class.new(work_package)) }

  before do
    allow(Wikis::PageLinkService).to receive(:new).and_return(page_link_service)
    render_component
  end

  context "without inline or referencing page links" do
    it "renders the turbo-frame wrapper without any section", :aggregate_failures do
      expect(page).to have_css("turbo-frame#work-package-wikis-tab-content")
      expect(page).to have_no_text(I18n.t("wikis.work_package_wikis_tab_component.inline_page_links"))
      expect(page).to have_no_text(I18n.t("wikis.work_package_wikis_tab_component.referencing_pages"))
    end
  end

  context "with inline and referencing page links" do
    let(:inline_page_links) { [page_info_result("Inline page")] }
    let(:referencing_wiki_pages) { [page_reference_result("Referencing page")] }

    it "renders a collapsible section for each link group" do
      expect(page).to have_css("collapsible-header", count: 2)
    end

    # The keep-collapsed-state controller keys the collapsed state it carries
    # over re-renders on these ids, so they must not be generated ones.
    it "gives every collapsible section a toggle with a stable target", :aggregate_failures do
      expect(page).to have_css("collapsible-header [data-collapsible-toggle][aria-controls='inline_page_links_list']")
      expect(page).to have_css("collapsible-header [data-collapsible-toggle][aria-controls='referencing_wiki_pages_list']")
    end

    it "renders the inline page links section", :aggregate_failures do
      expect(page).to have_text(I18n.t("wikis.work_package_wikis_tab_component.inline_page_links"))
      expect(page).to have_text("Inline page")
    end

    it "renders the referencing pages section", :aggregate_failures do
      expect(page).to have_text(I18n.t("wikis.work_package_wikis_tab_component.referencing_pages"))
      expect(page).to have_text("Referencing page")
    end
  end
end
