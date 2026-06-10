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

require "rails_helper"

RSpec.describe OpPrimer::ExpandableTextComponent, type: :component do
  def render_component(**, &)
    render_inline(described_class.new(**), &)
  end

  it "renders expandable truncated text" do
    render_component { "Long permission label" }

    expect(page).to have_css("div.d-flex.flex-items-baseline.gap-1.min-width-0[data-controller='truncation']")
    expect(page).to have_css(".Truncate.flex-1[data-truncation-target='truncate']", text: "Long permission label")
    expect(page).to have_css(".hidden-text-expander[data-truncation-target='expander'][hidden]", visible: :hidden)
    expect(page).to have_css("button.ellipsis-expander[aria-label='Show full text']", visible: :hidden)
  end

  it "merges classes and data attributes" do
    render_component(classes: "custom-class", data: { test_selector: "expandable-text" }) { "Long permission label" }

    expect(page).to have_css(
      "div.custom-class.gap-1.min-width-0[data-controller='truncation'][data-test-selector='expandable-text']"
    )
  end

  it "supports flex system arguments" do
    render_component(flex: 1) { "Long permission label" }

    expect(page).to have_css("div.flex-1")
  end
end
