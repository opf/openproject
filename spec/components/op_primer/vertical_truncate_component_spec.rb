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

RSpec.describe OpPrimer::VerticalTruncateComponent, type: :component do
  def render_component(**, &)
    render_inline(described_class.new(**), &)
  end

  it "wraps content in a line-clamped div" do
    render_component(lines: 3) { "Multi-line content" }

    expect(page).to have_css(
      "div.op-vertical-truncate[style*='--op-vertical-truncate-lines: 3']",
      text: "Multi-line content"
    )
  end

  it "applies the line count via a custom property, clamping to a minimum of 2" do
    render_component(lines: 99) { "Content" }
    expect(page).to have_css("div.op-vertical-truncate[style*='--op-vertical-truncate-lines: 99']")

    render_component(lines: 1) { "Content" }
    expect(page).to have_css("div.op-vertical-truncate[style*='--op-vertical-truncate-lines: 2']")
  end

  it "forwards system arguments to the wrapper" do
    render_component(flex: 1, data: { truncation_target: "truncate" }) { "Content" }

    expect(page).to have_css("div.op-vertical-truncate.flex-1[data-truncation-target='truncate']")
  end

  it "defaults to a div but allows overriding the tag" do
    render_component { "Content" }
    expect(page).to have_css("div.op-vertical-truncate")

    render_component(tag: :span) { "Content" }
    expect(page).to have_css("span.op-vertical-truncate")
  end
end
