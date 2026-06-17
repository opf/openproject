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

RSpec.describe OpenProject::Common::AttributeComponent, type: :component do
  def render_component(lines:)
    render_inline(described_class.new("dialog-1", "Description", "Some long text", lines:, format: false))
  end

  describe "truncation direction derived from `lines`" do
    it "truncates a single line horizontally" do
      render_component(lines: 1)

      expect(page).to have_css("[data-expandable-text-mode-value='single_line']")
      expect(page).to have_css(".Truncate[data-expandable-text-target='truncate']", text: "Some long text")
    end

    it "truncates multiple lines vertically with a matching op-vertical-truncate" do
      render_component(lines: 3)

      expect(page).to have_css("[data-expandable-text-mode-value='multi_line']")
      expect(page).to have_css(".op-vertical-truncate--lines-3[data-expandable-text-target='truncate']", text: "Some long text")
    end
  end

  describe "dialog expansion" do
    it "renders the full text in an owned dialog wired to the expander" do
      render_component(lines: 3)

      expect(page).to have_css("[data-expandable-text-inline-value='false']")
      expect(page).to have_css("button[data-show-dialog-id='dialog-1']", visible: :all)
      expect(page).to have_css("#dialog-1[data-test-selector='attribute-dialog']", visible: :all)
    end
  end
end
