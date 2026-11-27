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

RSpec.describe Settings::UserCustomFieldSections::ShowComponent, type: :component do
  let(:section) { create(:user_custom_field_section, name: "Contact", attribute_order: ["login"]) }
  let(:field_a) { create(:user_custom_field, user_custom_field_section: section) }
  let(:field_b) { create(:user_custom_field, user_custom_field_section: section) }

  subject(:rendered_component) do
    with_request_url "/admin/settings/user_custom_fields" do
      # custom_fields_by_key/attribute_order read the section's in-memory
      # state, which the fields' after_create_commit callback updates via a
      # separate `section` instance in the association chain, so this
      # `let`-bound object must be reloaded to see it.
      render_inline(described_class.new(user_custom_field_section: section.reload, sections: [section]))
    end
  end

  before do
    field_a
    field_b
  end

  it_behaves_like "a sortable-lists list", list_type: "user_field", name: "Contact"

  it_behaves_like "a Border Box sortable list", row_count: 3

  it_behaves_like "sortable-lists items", list_type: "user_field" do
    let(:sortable_records) { [field_a, field_b] }
  end

  it_behaves_like "no legacy drag-and-drop wiring"

  it "scopes the field list to the section, so drops address it by id" do
    expect(rendered_component).to have_css("[data-sortable-lists--list-id-value='#{section.id}']")
  end

  it "wires the BorderBox as the section item's drag preview target" do
    expect(rendered_component).to have_css(
      "[data-sortable-lists--list-type-value='user_field']" \
      "[data-sortable-lists--item-target='preview']"
    )
  end

  it "wires the section-header drag handle as the sortable-lists item handle target" do
    expect(rendered_component).to have_css(
      ".Box-header .handle[data-sortable-lists--item-target='handle']",
      count: 1
    )
  end

  it "narrows the filter text of every row to its attribute name, so the move-to-section items are not matched" do
    filter_texts = rendered_component.css("[data-filter--filter-list-target='searchItem'] .filter-target-visible-text")

    expect(filter_texts.map { |node| node.text.strip })
      .to contain_exactly(User.human_attribute_name(:login), field_a.name, field_b.name)
  end

  # Not the shared items contract: a built-in attribute owns no record, so the
  # row is keyed by its attribute name and labelled from the User model.
  it "wires the built-in attribute row as a sortable-lists item of type user_field" do
    expect(rendered_component).to have_css(
      "[data-controller~='sortable-lists--item']" \
      "[data-sortable-lists--item-id-value='login']" \
      "[data-sortable-lists--item-type-value='user_field']" \
      "[data-sortable-lists--item-label-value='#{User.human_attribute_name(:login)}']"
    )
  end
end
