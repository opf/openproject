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

RSpec.describe Wikis::InlinePageLinkMacroComponent, type: :component do
  let(:provider) { build_stubbed(:internal_wiki_provider) }
  let(:page_info) do
    Wikis::Adapters::Results::PageInfo.new(
      identifier: "1234",
      title: "Stormtrooper training",
      provider:,
      href: "https://wiki.death.star/Home/stormtrooper_training"
    )
  end
  let(:page_info_result) { Success(page_info) }

  subject(:render_component) { render_inline(described_class.new(page_info_result)) }

  before { render_component }

  it "renders a wiki page macro link with an ARIA description and no title" do
    expect(page).to have_link(text: page_info.title, href: page_info.href)
    expect(page).to have_css(
      ".op-inline-macro a[aria-description='#{I18n.t('wikis.page_links.aria_label')}']",
      text: page_info.title
    )
    expect(page).to have_no_css(".op-inline-macro[title]")
  end
end
