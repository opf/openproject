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

RSpec.describe Admin::Enumerations::ItemComponent, type: :component do
  let!(:priority) { create(:priority, name: "Urgent") }

  subject(:rendered_component) do
    with_request_url("/admin/settings/work_package_priorities") do
      render_inline(described_class.new(enumeration: priority))
    end
  end

  it "targets the drag handle for the item controller" do
    expect(rendered_component)
      .to have_css(".DragHandle[data-sortable-lists--item-target~='handle']", visible: :all)
  end

  # The four directions themselves are covered by the SortableLists::MoveMenu spec.
  it "renders the Move submenu carrying the moveMenu target with the shared move items" do
    expect(rendered_component).to have_css("li[data-sortable-lists--item-target~='moveMenu']", visible: :all) do |item|
      expect(item).to have_css("[role='menuitem']", text: I18n.t(:button_move), visible: :all) do |trigger|
        expect(rendered_component)
          .to have_css("##{trigger['aria-controls']} li[data-sortable-lists--item-target~='moveItem']", count: 4, visible: :all)
      end
    end
  end

  it "posts no move_to form", :aggregate_failures do
    expect(rendered_component).to have_no_field("move_to", type: :hidden)
    expect(rendered_component).to have_no_field("position", type: :hidden)
  end

  it "renders exactly one divider, so hiding the Move submenu leaves a single separator" do
    expect(rendered_component).to have_css("li.ActionList-sectionDivider", count: 1, visible: :all)
  end

  it "keeps Edit and Delete in the menu", :aggregate_failures do
    expect(rendered_component).to have_link(I18n.t(:button_edit), visible: :all)
    expect(rendered_component).to have_button(I18n.t(:button_delete), visible: :all)
  end
end
