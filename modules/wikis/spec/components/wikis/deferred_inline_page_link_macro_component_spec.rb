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

RSpec.describe Wikis::DeferredInlinePageLinkMacroComponent, type: :component do
  subject(:render_component) do
    render_inline(described_class.new(identifier: "1234", provider_id: "42"))
  end

  before { render_component }

  it "renders the loading wiki page macro with an ARIA label and no title" do
    expect(page).to have_css("turbo-frame[data-type='wiki-page-link']")
    expect(page).to have_css(
      ".op-inline-macro[aria-label='#{I18n.t('wikis.deferred_inline_page_link_macro_component.aria_label')}']"
    )
    expect(page).to have_no_css(".op-inline-macro[title]")
  end
end
