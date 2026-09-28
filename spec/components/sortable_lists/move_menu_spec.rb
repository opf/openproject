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

RSpec.describe SortableLists::MoveMenu, type: :component do
  let(:harness_class) do
    Class.new(ApplicationComponent) do
      include SortableLists::MoveMenu

      def self.name
        "MoveMenuHarnessComponent"
      end

      def call
        render(Primer::Alpha::ActionMenu.new) do |menu|
          menu.with_show_button { "Actions" }
          with_move_items(menu)
        end
      end
    end
  end

  let(:move_items) do
    page.all("li[data-sortable-lists--item-target~='moveItem']", visible: :all)
  end

  before { render_inline(harness_class.new) }

  it "renders the four directions in top, up, down, bottom order" do
    expect(move_items.pluck("data-sortable-lists--item-direction-param"))
      .to eq(%w[top up down bottom])
  end

  it "wires every item to the item controller's move action" do
    expect(move_items.pluck("data-action"))
      .to all(eq("click->sortable-lists--item#move"))
  end

  it "labels each direction with the existing sort translations and icons" do
    {
      "top" => [:label_sort_highest, "move-to-top"],
      "up" => [:label_sort_higher, "chevron-up"],
      "down" => [:label_sort_lower, "chevron-down"],
      "bottom" => [:label_sort_lowest, "move-to-bottom"]
    }.each do |direction, (label, icon)|
      item = page.find("li[data-sortable-lists--item-direction-param='#{direction}']", visible: :all)

      expect(item).to have_button(I18n.t(label), visible: :all)
      expect(item).to have_css(".octicon-#{icon}", visible: :all)
    end
  end

  it "does not expose the builder as public component API" do
    expect(harness_class.new).not_to respond_to(:with_move_items)
  end

  describe "DIRECTIONS" do
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
