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

  subject(:rendered_component) do
    with_request_url "/admin/settings/project_custom_fields" do
      # `custom_fields_in_order` reads the section's in-memory
      # `attribute_order`, which the fields' after_create_commit
      # callback updates via a separate `section` instance in the
      # association chain, so this `let`-bound object must be
      # reloaded to see it.
      render_inline(described_class.new(project_custom_field_section: section.reload))
    end
  end

  context "with custom fields" do
    let!(:field_a) { create(:project_custom_field, project_custom_field_section: section) }
    let!(:field_b) { create(:project_custom_field, project_custom_field_section: section) }

    it_behaves_like "a sortable Border Box List",
                    list_type: "custom_field", item_type: "custom_field", item_count: 2

    # The box itself is no longer a draggable item (that role now lives on the
    # collection's row wrapper in IndexComponent, via `sortable_handle: true`
    # rather than `sortable_item:` here) — it only needs a bare preview target
    # and a wired header drag handle for the outer drag to work.
    it "wires the box root as a bare preview target, without its own item controller" do
      expect(rendered_component).to have_element(:div, id: "project-custom-field-section-#{section.id}") do |box|
        expect(box["data-sortable-lists--item-target"]).to include("preview")
        expect(box["data-controller"]).not_to include("sortable-lists--item")
      end
    end

    it "wires the header drag handle" do
      # Scoped to `.Box-header`: each field row also renders its own
      # `.handle` (see custom_field_row_component.html.erb), so an
      # unscoped match would pass even if the header's own handle broke.
      expect(rendered_component).to have_css(".Box-header") do |header|
        expect(header).to have_element(:div, class: "handle", count: 1) do |handle|
          expect(handle["data-sortable-lists--item-target"]).to include("handle")
        end
      end
    end

    it "wires each field row's li with the sortable-lists item label" do
      [field_a, field_b].each do |field|
        expect(rendered_component).to have_css("li[data-sortable-lists--item-id-value='#{field.id}']") do |row|
          expect(row["data-controller"]).to include("sortable-lists--item")
          expect(row["data-sortable-lists--item-type-value"]).to eq("custom_field")
          expect(row["data-sortable-lists--item-label-value"]).to eq(field.name)
        end
      end
    end

    it "renders the position selector as an inline header action menu" do
      expect(rendered_component).to have_css(
        ".op-border-box-list-header--actions [data-test-selector='section-position-selector']"
      )
    end

    it "has no generic-drag-and-drop remnants" do
      expect(rendered_component.to_html).not_to match(
        /generic-drag-and-drop|target-container-accessor|target-allowed-drag-type|draggable-type|drop-url/
      )
    end
  end

  context "with no custom fields" do
    it "renders the custom empty row with its new-attribute menu and no default blankslate" do
      expect(rendered_component).to have_css("li[data-empty-list-item]")
      expect(rendered_component).to have_css("[data-test-selector='new-project-custom-field-in-section-button']")
      expect(rendered_component).to have_no_css(".blankslate")
    end

    # ShowComponent always fills its own custom empty row above, so
    # BorderBoxListComponent's built-in empty state never fires here. This
    # proves the underlying primitive it is built from — configured with the
    # exact `sortable_list:` this section passes — renders the drop-zone
    # overlay labeled with the section's own list name once it has no items,
    # now that `sortable_list:` unconditionally wires the list role onto the
    # box root (rather than falling back onto the items `<ul>` whenever
    # combined with `sortable_item:`, which made the box root's own
    # `[data-drop-container]` ancestry unreliable for this overlay).
    it "renders the drop-zone overlay labeled with the section's list name once the underlying list is empty" do
      rendered = render_inline(
        OpenProject::Common::BorderBoxListComponent.new(
          container: "project-custom-field-section-#{section.id}",
          sortable_list: OpPrimer::SortableLists::List.for(section, type: "custom_field")
        )
      )

      expect(rendered).to have_css(".op-border-box-list-empty-state--drop-overlay", text: section.name)
    end
  end
end
