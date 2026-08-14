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

RSpec.describe Wikis::InlinePageLinksComponent, type: :component do
  let(:provider) { build_stubbed(:xwiki_provider) }
  let(:work_package) { build_stubbed(:work_package) }
  let(:inline_page_links) { [] }

  let(:page_info_result) do
    Dry::Monads::Success(
      Wikis::Adapters::Results::PageInfo.new(
        identifier: "inline-page",
        title: "Inline page",
        href: "https://wiki.example.com/inline-page",
        provider:
      )
    )
  end

  let(:page_link_service) do
    instance_double(
      Wikis::PageLinkService,
      inline_page_link_infos_for: inline_page_links,
      relation_page_link_keys_for: Set.new
    )
  end

  let(:heading) { I18n.t("wikis.work_package_wikis_tab_component.inline_page_links") }
  let(:wrapper) { page.find("##{described_class.wrapper_key}") }

  subject(:render_component) { render_inline(described_class.new(work_package)) }

  before do
    allow(Wikis::PageLinkService).to receive(:new).and_return(page_link_service)
    render_component
  end

  context "without inline page links" do
    it "renders an empty wrapper, so that no gap is left between the surrounding sections", :aggregate_failures do
      expect(wrapper).to have_no_css("*")
      expect(page).to have_no_text(heading)
    end
  end

  context "with inline page links" do
    let(:inline_page_links) { [page_info_result] }

    it "renders the collapsible section inside the wrapper", :aggregate_failures do
      expect(wrapper).to have_css("collapsible-header")
      expect(wrapper).to have_text(heading)
      expect(wrapper).to have_text("Inline page")
    end
  end
end
