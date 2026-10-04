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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "rails_helper"

RSpec.describe SortableLists::MoveMenu, type: :component do
  def harness_class_calling(builder, system_arguments: {})
    Class.new(ApplicationComponent) do
      include SortableLists::MoveMenu

      def self.name
        "MoveMenuHarnessComponent"
      end

      define_method(:call) do
        render(Primer::Alpha::ActionMenu.new) do |menu|
          menu.with_show_button { "Actions" }
          send(builder, menu, **system_arguments)
        end
      end
    end
  end

  let(:directions) do
    {
      "top" => ["Move to top", :"move-to-top"],
      "up" => ["Move up", :"chevron-up"],
      "down" => ["Move down", :"chevron-down"],
      "bottom" => ["Move to bottom", :"move-to-bottom"]
    }
  end

  before { render_inline(harness_class.new) }

  describe "#with_move_items" do
    let(:harness_class) { harness_class_calling(:with_move_items) }

    it "renders the four directions in top, up, down, bottom order" do
      expect(page.all(:menuitem).map { it.text.squish })
        .to eq(["Move to top", "Move up", "Move down", "Move to bottom"])
    end

    it "gives each direction its icon", :aggregate_failures do
      directions.each_value do |label, icon|
        expect(page).to have_selector(:menuitem, label) do |item|
          expect(item).to have_octicon(icon)
        end
      end
    end

    it "wires every item to the item controller's move action", :aggregate_failures do
      directions.each do |direction, (label, _icon)|
        expect(page).to have_element(:li, "data-sortable-lists--item-direction-param": direction) do |item|
          expect(item["data-sortable-lists--item-target"]).to eq("moveItem")
          expect(item["data-action"]).to eq("click->sortable-lists--item#move")
          expect(item).to have_selector(:menuitem, label)
        end
      end
    end
  end

  describe "#with_move_submenu" do
    let(:system_arguments) { {} }
    let(:harness_class) { harness_class_calling(:with_move_submenu, system_arguments:) }

    it "renders a Move item with the incoming-arrow icon that opens a submenu", :aggregate_failures do
      expect(page).to have_selector(:menuitem, "Move", exact: true, count: 1) do |item|
        expect(item).to have_octicon(:"op-arrow-in")
        expect(item["aria-haspopup"]).to eq("true")
      end
    end

    it "marks the Move item as the target the item controller hides" do
      expect(page).to have_element(:li, "data-sortable-lists--item-target": "moveMenu", count: 1) do |item|
        expect(item).to have_selector(:menuitem, "Move", exact: true)
      end
    end

    it "renders the four directions into the submenu the Move item controls" do
      move_item = page.find(:menuitem, "Move", exact: true)

      expect(page).to have_selector(:menu, id: move_item["aria-controls"]) do |submenu|
        expect(submenu.all(:menuitem).map { it.text.squish })
          .to eq(["Move to top", "Move up", "Move down", "Move to bottom"])
      end
    end

    context "with caller-supplied additional arguments" do
      let(:system_arguments) do
        {
          classes: "additional-class",
          data: { projects__settings__border_box_filter_target: "hideWhenFiltering" }
        }
      end

      it "merges the caller's data with the moveMenu target data and keeps other system arguments",
         :aggregate_failures do
        expect(page).to have_element(:li, "data-sortable-lists--item-target": "moveMenu", count: 1) do |item|
          expect(item["data-projects--settings--border-box-filter-target"]).to eq("hideWhenFiltering")
          expect(item[:class]).to include("additional-class")
          expect(item).to have_selector(:menuitem, "Move", exact: true)
        end
      end
    end
  end

  describe "DIRECTIONS" do
    let(:harness_class) { harness_class_calling(:with_move_items) }

    it "is frozen" do
      expect(described_class::DIRECTIONS).to be_frozen
    end

    it "derives the Stimulus data from the direction" do
      expect(described_class::DIRECTIONS.first.item_data).to eq(
        sortable_lists__item_target: "moveItem",
        sortable_lists__item_direction_param: "top",
        action: "click->sortable-lists--item#move"
      )
    end
  end
end
