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

  subject do
    with_request_url "/admin/settings/user_custom_fields" do
      render_inline(described_class.new(user_custom_field_sections: [section_a, section_b]))
    end
  end

  before do
    section_a
    section_b
  end

  it "wires the wrapper as the sortable-lists root with per-type move URL templates" do
    subject

    root = page.find("[data-controller='sortable-lists']", visible: :all)
    move_url_templates = JSON.parse(root["data-sortable-lists-move-url-templates-value"])

    expect(move_url_templates["user_custom_field_section"]).to include("/admin/settings/user_custom_field_sections/{id}/drop")
    expect(move_url_templates["user_field"]).to include("/admin/settings/user_custom_field_section_fields/{id}/drop")
  end

  it "wires the root's outlet selectors so they actually resolve to the rendered list/items" do
    subject

    root = page.find("[data-controller='sortable-lists']", visible: :all)
    list_outlet_selector = root["data-sortable-lists-sortable-lists--list-outlet"]
    item_outlet_selector = root["data-sortable-lists-sortable-lists--item-outlet"]

    expect(list_outlet_selector).to be_present
    expect(item_outlet_selector).to be_present

    # Prove the selector-to-DOM link, not just attribute presence: if the
    # dasherization or the `##{wrapper_key}` interpolation drifts, these
    # selectors silently stop matching anything and the outlets connect
    # to nothing with no failing test or console warning.
    expect(page).to have_css(list_outlet_selector)
    expect(page).to have_css(item_outlet_selector)
  end

  it "wires the sections flex container as a sortable-lists list of type user_custom_field_section without a list id" do
    subject

    expect(page).to have_css(
      "[data-controller~='sortable-lists--list']" \
      "[data-sortable-lists--list-type-value='user_custom_field_section']" \
      "[data-sortable-lists--list-accepted-type-value='user_custom_field_section']" \
      ":not([data-sortable-lists--list-id-value])"
    )
  end

  it "wires each section row as a sortable-lists item of type user_custom_field_section" do
    subject

    [section_a, section_b].each do |section|
      expect(page).to have_css(
        "[data-controller~='sortable-lists--item']" \
        "[data-sortable-lists--item-id-value='#{section.id}']" \
        "[data-sortable-lists--item-type-value='user_custom_field_section']" \
        "[data-sortable-lists--item-label-value='#{section.name}']"
      )
    end
  end

  # The section's own sortable-lists wiring has no generic-drag-and-drop
  # remnants; its rendered ShowComponent still carries them for its field
  # list until that is migrated too (see show_component_spec.rb).
  it "has no generic-drag-and-drop remnants on the sections list itself" do
    subject

    root = page.find("[data-controller='sortable-lists']", visible: :all)
    expect(root["data-controller"]).to eq("sortable-lists")
    list = page.find(
      "[data-controller~='sortable-lists--list'][data-sortable-lists--list-type-value='user_custom_field_section']",
      visible: :all
    )
    expect(list[:class].to_s).not_to include("dragula-container")
  end
end
