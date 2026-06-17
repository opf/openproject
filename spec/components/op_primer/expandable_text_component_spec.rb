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

  describe "single-line mode (default)" do
    it "renders expandable truncated text" do
      render_component { "Long permission label" }

      expect(page).to have_css(
        "div.d-flex.flex-items-baseline.gap-1.min-width-0" \
        "[data-controller='expandable-text']" \
        "[data-expandable-text-mode-value='single_line']" \
        "[data-expandable-text-inline-value='true']"
      )
      expect(page).to have_css(".Truncate.flex-1[data-expandable-text-target='truncate']", text: "Long permission label")
      expect(page).to have_css(".hidden-text-expander[data-expandable-text-target='expander'][hidden]", visible: :hidden)
      expect(page).to have_button(class: "ellipsis-expander", aria: { label: "Show full text" }, visible: :hidden)
    end

    it "merges classes and data attributes" do
      render_component(classes: "custom-class", data: { test_selector: "expandable-text" }) { "Long permission label" }

      expect(page).to have_css(
        "div.custom-class.gap-1.min-width-0[data-controller='expandable-text'][data-test-selector='expandable-text']"
      )
    end

    it "supports flex system arguments" do
      render_component(flex: 1) { "Long permission label" }

      expect(page).to have_css("div.flex-1")
    end
  end

  describe "multi-line mode" do
    it "renders an op-vertical-truncate instead of a Truncate" do
      render_component(truncate: :multi_line, lines: 3) { "Multi-line content" }

      expect(page).to have_css(
        "div.d-flex[data-expandable-text-mode-value='multi_line']"
      )
      expect(page).to have_css(
        "div.op-vertical-truncate.op-vertical-truncate--lines-3[data-expandable-text-target='truncate']",
        text: "Multi-line content"
      )
      expect(page).to have_no_css(".Truncate")
    end

    it "uses flex-end alignment for multi-line mode" do
      render_component(truncate: :multi_line) { "Content" }

      expect(page).to have_css("div.flex-items-end")
      expect(page).to have_no_css("div.flex-items-baseline")
    end

    it "supports configurable line count" do
      render_component(truncate: :multi_line, lines: 5) { "Content" }

      expect(page).to have_css("div.op-vertical-truncate--lines-5[data-expandable-text-target='truncate']")
    end

    it "clamps the line count to the supported range" do
      render_component(truncate: :multi_line, lines: 99) { "Content" }
      expect(page).to have_css("div.op-vertical-truncate--lines-8[data-expandable-text-target='truncate']")

      render_component(truncate: :multi_line, lines: 1) { "Content" }
      expect(page).to have_css("div.op-vertical-truncate--lines-2[data-expandable-text-target='truncate']")
    end
  end

  describe "dialog expansion (expansion: :dialog)" do
    def render_with_dialog(**)
      render_component(expansion: :dialog, **) do |component|
        component.with_dialog(title: "Full text") { "Full content" }
        "Content"
      end
    end

    it "sets the inline value to false and renders the owned dialog" do
      render_with_dialog(dialog_id: "my-dialog")

      expect(page).to have_element("div", "data-expandable-text-inline-value": "false")
      expect(page).to have_css("#my-dialog", visible: :all)
    end

    it "wires the expander button to the owned dialog without the caller setting it" do
      render_with_dialog(dialog_id: "my-dialog")

      expect(page).to have_element("button", "data-show-dialog-id": "my-dialog", visible: :all)
    end

    it "exposes the dialog to assistive technology on the expander button" do
      render_with_dialog(dialog_id: "my-dialog")

      expect(page).to have_button(aria: { haspopup: "dialog", controls: "my-dialog" }, visible: :all)
    end

    it "generates a dialog id when none is given" do
      render_with_dialog

      expect(page).to have_css("[id^='expandable-text-dialog-']", visible: :all)
    end

    it "falls back to a default dialog showing the full content when no slot is provided" do
      render_component(expansion: :dialog, dialog_id: "my-dialog") { "Full content" }

      expect(page).to have_css("#my-dialog", visible: :all)
      expect(page).to have_css("#my-dialog", text: "Full content", visible: :all)
      expect(page).to have_element("button", "data-show-dialog-id": "my-dialog", visible: :all)
    end
  end

  describe "expander_arguments" do
    it "merges additional arguments into the expander" do
      render_component(
        expander_arguments: { button_arguments: { "data-show-dialog-id": "my-dialog" } }
      ) { "Content" }

      expect(page).to have_css(
        ".hidden-text-expander[data-expandable-text-target='expander']",
        visible: :hidden
      )
    end

    it "does not mutate the caller-provided hash, including nested button_arguments" do
      arguments = { mt: 3, button_arguments: { classes: "x" } }

      render_component(expander_arguments: arguments) { "Content" }

      expect(arguments).to eq(mt: 3, button_arguments: { classes: "x" })
    end
  end

  describe "validation" do
    it "raises for an invalid truncate value in development and test" do
      expect { render_component(truncate: :diagonal) { "Content" } }
        .to raise_error(Primer::FetchOrFallbackHelper::InvalidValueError)
    end

    it "raises for an invalid expansion in development and test" do
      expect { render_component(expansion: :sideways) { "Content" } }
        .to raise_error(Primer::FetchOrFallbackHelper::InvalidValueError)
    end
  end
end
