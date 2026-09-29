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

RSpec.describe SortableLists::MoveMenuItems, type: :component do
  describe "DIRECTIONS" do
    it "carries direction, label, icon and legacy move_to for every entry, in menu order" do
      expect(described_class::DIRECTIONS).to eq(
        [
          { direction: :top, label: :label_sort_highest, icon: :"move-to-top", move_to: :highest },
          { direction: :up, label: :label_sort_higher, icon: :"chevron-up", move_to: :higher },
          { direction: :down, label: :label_sort_lower, icon: :"chevron-down", move_to: :lower },
          { direction: :bottom, label: :label_sort_lowest, icon: :"move-to-bottom", move_to: :lowest }
        ]
      )
    end

    it "is frozen as an array and entry by entry" do
      expect(described_class::DIRECTIONS).to be_frozen
      expect(described_class::DIRECTIONS).to all(be_frozen)
    end
  end

  describe "#render_into" do
    before do
      render_inline(Primer::Alpha::ActionMenu::List.new(menu_id: "test-menu")) do |list|
        described_class.new(dom_key: :story).render_into(list)
      end
    end

    it "renders one item per direction, in menu order" do
      expect(page).to have_css("li", count: 4)
      expect(page.all("li").map { it.text.strip })
        .to eq(["Move to top", "Move up", "Move down", "Move to bottom"])
    end

    # The wiring must sit on the `<li>`, not the button: the controller's targets
    # and the action-menu API's disableItem/enableItem both address that element.
    it "renders every item with its dom_key id, label, icon and Stimulus wiring",
       :aggregate_failures do
      [
        ["top", "story_menu_top", "Move to top", "octicon-move-to-top"],
        ["up", "story_menu_up", "Move up", "octicon-chevron-up"],
        ["down", "story_menu_down", "Move down", "octicon-chevron-down"],
        ["bottom", "story_menu_bottom", "Move to bottom", "octicon-move-to-bottom"]
      ].each do |direction, id, label, icon|
        item = page.find(
          :element, :li,
          "data-sortable-lists--item-direction-param": direction,
          "data-sortable-lists--item-target": "moveItem",
          "data-action": "click->sortable-lists--item#move"
        )
        expect(item).to have_element(:button, id:, text: label)
        expect(item).to have_css(".#{icon}")
      end
    end
  end
end
