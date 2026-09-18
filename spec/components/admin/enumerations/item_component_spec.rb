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
  let(:move_items) do
    rendered_component.css("li[data-sortable-lists--item-target~='moveItem']")
  end

  subject(:rendered_component) do
    with_request_url("/admin/settings/work_package_priorities") do
      render_inline(described_class.new(enumeration: priority))
    end
  end

  it "targets the drag handle for the item controller" do
    expect(rendered_component)
      .to have_css(".DragHandle[data-sortable-lists--item-target~='handle']", visible: :all)
  end

  it "renders a Move submenu carrying the moveMenu target" do
    expect(rendered_component)
      .to have_css("li[data-sortable-lists--item-target~='moveMenu']", visible: :all)
  end

  it "renders the four move directions in order" do
    expect(move_items.pluck("data-sortable-lists--item-direction-param"))
      .to eq(%w[top up down bottom])
  end

  it "wires every move item to the item controller" do
    expect(move_items.pluck("data-action"))
      .to all(eq("click->sortable-lists--item#move"))
  end

  it "labels the move items with the existing sort translations", :aggregate_failures do
    labels = %i[label_sort_highest label_sort_higher label_sort_lower label_sort_lowest]

    labels.each do |label|
      expect(rendered_component).to have_button(I18n.t(label), visible: :all)
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
