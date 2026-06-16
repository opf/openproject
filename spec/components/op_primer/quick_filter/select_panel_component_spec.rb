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

RSpec.describe OpPrimer::QuickFilter::SelectPanelComponent, type: :component do
  include QuickFilterHelpers

  let(:project) { build_stubbed(:project) }
  let(:query) { build_meeting_query }

  subject(:component) do
    described_class.new(
      name: "Project",
      query:,
      filter_key: :project_id,
      path_args: [nil, :meetings]
    )
  end

  def render_with_items
    render_inline(component) do |c|
      c.with_item(label: "Project 1", value: 1)
      c.with_item(label: "Project 2", value: 2)
    end
  end

  context "when rendering with items" do
    before { render_with_items }

    it "renders all items" do
      expect(page).to have_text("Project 1")
      expect(page).to have_text("Project 2")
    end

    it "renders the select panel quick filter" do
      expect(page).to have_css("[data-controller='quick-filter--select-panel']")
    end
  end

  context "when no items are given" do
    before { render_inline(component) }

    it "does not render" do
      expect(page).to have_no_css("[data-controller='quick-filter--select-panel']")
    end
  end

  context "when an item matches the active filter value" do
    let(:query) { build_meeting_query.where("project_id", "=", ["1"]) }

    before { render_with_items }

    it "marks the matching item as selected" do
      expect(page).to have_css("[aria-selected='true']", text: "Project 1", visible: :all)
    end

    it "does not mark the other item as selected" do
      expect(page).to have_no_css("[aria-selected='true']", text: "Project 2", visible: :all)
    end
  end

  context "when multiple items match the active filter" do
    let(:query) { build_meeting_query.where("project_id", "=", ["1", "2"]) }

    before { render_with_items }

    it "marks all matching items as selected" do
      expect(page).to have_css("[aria-selected='true']", text: "Project 1", visible: :all)
      expect(page).to have_css("[aria-selected='true']", text: "Project 2", visible: :all)
    end
  end

  context "when no filter is active" do
    before { render_with_items }

    it "marks no items as selected" do
      expect(page).to have_no_css("[aria-selected='true']", visible: :all)
    end
  end

  context "with the show button" do
    context "when no filter is active" do
      before { render_with_items }

      it "shows the component name in muted text" do
        expect(page).to have_button("Project")
        expect(page).to have_css("button .color-fg-muted", text: "Project")
      end

      it "does not show a counter" do
        expect(page).to have_no_css("button .Counter")
      end

      it "renders the trailing icon in muted color" do
        expect(page).to have_css("button .octicon-triangle-down.color-fg-muted")
      end
    end

    context "when one item is active" do
      let(:query) { build_meeting_query.where("project_id", "=", ["1"]) }

      before { render_with_items }

      it "shows the component name as the label" do
        expect(page).to have_button("Project")
      end

      it "does not render muted text" do
        expect(page).to have_no_css("button .color-fg-muted", text: "Project")
      end

      it "shows a counter with the selected count" do
        expect(page).to have_css("button .Counter", text: "1")
      end

      it "renders the trailing icon in default color" do
        expect(page).to have_css("button .octicon-triangle-down.color-fg-default")
      end
    end

    context "when multiple items are active" do
      let(:query) { build_meeting_query.where("project_id", "=", ["1", "2"]) }

      before { render_with_items }

      it "shows the component name as the label" do
        expect(page).to have_button("Project")
      end

      it "shows a counter with the selected count" do
        expect(page).to have_css("button .Counter", text: "2")
      end
    end
  end

  context "with the footer" do
    context "when no filter is active" do
      before { render_with_items }

      it "renders an apply button" do
        expect(page).to have_test_selector("quick-filter-apply-button")
      end

      it "does not render a clear button" do
        expect(page).to have_no_test_selector("quick-filter-clear-button")
      end
    end

    context "when a filter is active" do
      let(:query) { build_meeting_query.where("project_id", "=", ["1"]) }

      before { render_with_items }

      it "renders a clear button" do
        expect(page).to have_test_selector("quick-filter-clear-button")
      end

      it "renders an apply button" do
        expect(page).to have_test_selector("quick-filter-apply-button")
      end
    end
  end

  context "when other filters are active" do
    let(:query) { build_meeting_query.where("time", "=", ["future"]) }

    before { render_with_items }

    it "preserves the operator and values of other filters unchanged" do
      base_url = page.find("[data-controller='quick-filter--select-panel']")[
        "data-quick-filter--select-panel-base-url-value"
      ]
      time_filter = filters_from_base_url(base_url).find { |f| f.key?("time") }
      original = query.find_active_filter(:time)

      expect(time_filter["time"]["operator"]).to eq(original.operator.to_s)
      expect(time_filter["time"]["values"]).to eq(original.values)
    end
  end
end
