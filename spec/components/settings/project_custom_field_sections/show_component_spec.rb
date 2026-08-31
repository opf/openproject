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

RSpec.describe Settings::ProjectCustomFieldSections::ShowComponent, type: :component do
  let(:section) { create(:project_custom_field_section) }
  let(:field_a) { create(:project_custom_field, project_custom_field_section: section) }
  let(:field_b) { create(:project_custom_field, project_custom_field_section: section) }

  subject do
    with_request_url "/admin/settings/project_custom_fields" do
      # `custom_fields_in_order` reads the section's in-memory
      # `attribute_order`, which the fields' after_create_commit
      # callback updates via a separate `section` instance in the
      # association chain, so this `let`-bound object must be
      # reloaded to see it.
      render_inline(described_class.new(project_custom_field_section: section.reload))
    end
  end

  before do
    field_a
    field_b
  end

  it "wires the BorderBox as a sortable-lists list of type custom_field scoped to the section" do
    subject

    expect(page).to have_css(
      "[data-controller~='sortable-lists--list']" \
      "[data-sortable-lists--list-type-value='custom_field']" \
      "[data-sortable-lists--list-accepted-type-value='custom_field']" \
      "[data-sortable-lists--list-id-value='#{section.id}']" \
      "[data-sortable-lists--list-name-value='#{section.name}']"
    )
  end

  it "wires the BorderBox as the section item's drag preview target" do
    subject

    # The box, not the row wrapper, is the preview so the native drag
    # snapshot's margin whitespace and squared-off corners never show.
    expect(page).to have_css(
      "[data-sortable-lists--list-type-value='custom_field']" \
      "[data-sortable-lists--item-target='preview']"
    )
  end

  it "wires the section-header drag handle as the sortable-lists item handle target" do
    subject

    # Scoped to the header: the two field-row handles carry the same
    # class + data attribute, so an unscoped assertion here would stay
    # green even if the header's own handle lost its `data:` hash.
    expect(page).to have_css(
      ".Box-header .handle[data-sortable-lists--item-target='handle']",
      count: 1
    )
  end

  it "wires each field row's li as a sortable-lists item of type custom_field" do
    subject

    [field_a, field_b].each do |field|
      expect(page).to have_css(
        "li[data-controller~='sortable-lists--item']" \
        "[data-sortable-lists--item-id-value='#{field.id}']" \
        "[data-sortable-lists--item-type-value='custom_field']" \
        "[data-sortable-lists--item-label-value='#{field.name}']"
      )
    end
  end

  it "has no generic-drag-and-drop remnants" do
    subject

    expect(page.native.to_html).not_to match(
      /generic-drag-and-drop|target-container-accessor|target-allowed-drag-type|draggable-type|drop-url/
    )
  end
end
