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
require Rails.root.join("lookbook/previews/op_primer/expandable_text_component_preview").to_s

RSpec.describe OpPrimer::ExpandableTextComponentPreview, :component_preview, :js do
  it "renders the default (single-line) preview" do
    visit_preview(:default, from: described_class)

    expect(page).to have_css("[data-controller='expandable-text'][data-expandable-text-mode-value='single_line']")
    expect(page).to have_css(".Truncate[data-expandable-text-target='truncate']")
  end

  it "renders the hidden_for_short_texts preview" do
    visit_preview(:hidden_for_short_texts, from: described_class)

    expect(page).to have_css("[data-controller='expandable-text']", text: "Short text")
  end

  it "renders the in_table preview" do
    visit_preview(:in_table, from: described_class)

    expect(page).to have_css("table [data-controller='expandable-text']")
    expect(page).to have_text("Automatically managed project folders")
  end

  it "renders the multi_line preview with a configurable line count" do
    visit_preview(:multi_line, from: described_class, params: { lines: 4 })

    expect(page).to have_css("[data-expandable-text-mode-value='multi_line']")
    expect(page).to have_css(
      ".op-vertical-truncate[style*='--op-vertical-truncate-lines: 4'][data-expandable-text-target='truncate']"
    )
  end

  it "renders the dialog preview (inline: false)" do
    visit_preview(:dialog, from: described_class)

    expect(page).to have_css("[data-expandable-text-inline-value='false']")
    expect(page).to have_css("#expandable-text-dialog", visible: :all)
  end

  it "renders the playground preview" do
    visit_preview(:playground, from: described_class, params: { truncate: "multi_line", lines: 2 })

    expect(page).to have_css("[data-controller='expandable-text'][data-expandable-text-mode-value='multi_line']")
    expect(page).to have_css(
      ".op-vertical-truncate[style*='--op-vertical-truncate-lines: 2'][data-expandable-text-target='truncate']"
    )
  end

  describe "accessibility", :selenium do
    let(:preview_content) { ".viewcomponent-preview--content" }

    it "passes axe-core accessibility tests for the default preview, collapsed and expanded" do
      visit_preview(:default, from: described_class)

      expect(page).to have_button(accessible_name: "Show full text", aria: { expanded: false })
      expect(page).to be_axe_clean.within preview_content

      click_button accessible_name: "Show full text"

      expect(page).to have_button(accessible_name: "Collapse text", aria: { expanded: true })
      expect(page).to be_axe_clean.within preview_content
    end

    it "passes axe-core accessibility tests for the hidden_for_short_texts preview" do
      visit_preview(:hidden_for_short_texts, from: described_class)

      expect(page).to have_text("Short text")
      expect(page).to have_no_button(accessible_name: "Show full text")
      expect(page).to be_axe_clean.within preview_content
    end

    it "passes axe-core accessibility tests for the in_table preview, collapsed and expanded" do
      visit_preview(:in_table, from: described_class)

      expect(page).to have_button(accessible_name: "Show full text", count: 2)
      expect(page).to be_axe_clean.within preview_content

      within(:row, "Create and manage public saved views for work packages") do
        click_button accessible_name: "Show full text"
      end

      expect(page).to have_button(accessible_name: "Collapse text", aria: { expanded: true })
      expect(page).to be_axe_clean.within preview_content
    end

    it "passes axe-core accessibility tests for the multi_line preview, collapsed and expanded" do
      visit_preview(:multi_line, from: described_class)

      expect(page).to have_button(accessible_name: "Show full text", aria: { expanded: false })
      expect(page).to be_axe_clean.within preview_content

      click_button accessible_name: "Show full text"

      expect(page).to have_button(accessible_name: "Collapse text", aria: { expanded: true })
      expect(page).to be_axe_clean.within preview_content
    end

    it "passes axe-core accessibility tests for the dialog preview, closed and open" do
      visit_preview(:dialog, from: described_class)

      expect(page).to have_button(accessible_name: "Show full text")
      expect(page).to be_axe_clean.within preview_content

      click_button accessible_name: "Show full text"

      expect(page).to have_selector(:dialog)
      wait_for_size_animation_completion("dialog[open]")
      expect(page).to be_axe_clean.within preview_content
    end

    it "passes axe-core accessibility tests for the playground preview with a custom dialog" do
      visit_preview(:playground, from: described_class, params: { truncate: :multi_line, expansion: :dialog })

      click_button accessible_name: "Show full text"

      expect(page).to have_selector(:dialog, "Full text")
      wait_for_size_animation_completion("dialog[open]")
      expect(page).to be_axe_clean.within preview_content
    end
  end
end
