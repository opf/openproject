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

RSpec.describe Settings::UserCustomFieldSections::IndexComponent, type: :component do
  let(:section_a) { create(:user_custom_field_section) }
  let(:section_b) { create(:user_custom_field_section) }
  let(:root) { rendered_component.at_css("[data-controller='sortable-lists']") }
  let(:sections_list) { rendered_component.at_css("[data-sortable-lists--list-type-value='user_custom_field_section']") }

  subject(:rendered_component) do
    with_request_url "/admin/settings/user_custom_fields" do
      render_inline(described_class.new(user_custom_field_sections: [section_a, section_b]))
    end
  end

  it_behaves_like "a sortable-lists root", wrapper_id: "settings-user-custom-field-sections-index-component"
  it_behaves_like "no legacy drag-and-drop wiring"

  # Not the shared list and items contracts: those describe a component owning
  # a single list of Border Box rows, while each section row here holds a whole
  # Border Box with a nested user_field list of its own (show_component_spec.rb
  # covers that one).
  it "wires the sections container as an unscoped sortable-lists list" do
    expect(sections_list["data-controller"]).to eq("sortable-lists--list")
    expect(sections_list["data-sortable-lists--list-accepted-type-value"]).to eq("user_custom_field_section")
    expect(sections_list["data-sortable-lists--list-id-value"]).to be_nil
  end

  it "wires each section row as a sortable item of type user_custom_field_section" do
    [section_a, section_b].each do |section|
      row = rendered_component.at_css(
        "[data-sortable-lists--item-type-value='user_custom_field_section']" \
        "[data-sortable-lists--item-id-value='#{section.id}']"
      )

      expect(row["data-controller"]).to eq("sortable-lists--item")
      expect(row["data-sortable-lists--item-label-value"]).to eq(section.name)
      expect(row).to have_css(".DragHandle[data-sortable-lists--item-target~='handle']")
    end
  end

  it "addresses each list type with its own move URL template" do
    move_url_templates = JSON.parse(root["data-sortable-lists-move-url-templates-value"])

    expect(move_url_templates["user_custom_field_section"]).to include("/admin/settings/user_custom_field_sections/{id}/drop")
    expect(move_url_templates["user_field"]).to include("/admin/settings/user_custom_field_section_fields/{id}/drop")
  end

  # Prove the selector-to-DOM link, not just attribute presence: if the
  # dasherization or the `##{wrapper_key}` interpolation drifts, these
  # selectors silently stop matching anything and the outlets connect
  # to nothing with no failing test or console warning.
  it "wires the root's outlet selectors so they actually resolve to the rendered list/items" do
    expect(rendered_component).to have_css(root["data-sortable-lists-sortable-lists--list-outlet"])
    expect(rendered_component).to have_css(root["data-sortable-lists-sortable-lists--item-outlet"])
  end
end
