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

require "spec_helper"

RSpec.describe CustomFieldsHelper do
  describe "#custom_field_tag_for_bulk_edit" do
    context "with a datetime custom field" do
      let(:custom_field) { build_stubbed(:wp_custom_field, :datetime) }
      let(:value) { nil }
      let(:field_name) { "work_package[custom_field_values][#{custom_field.id}]" }

      subject(:rendered) do
        Capybara.string(helper.custom_field_tag_for_bulk_edit("work_package", custom_field, nil, value))
      end

      it "renders the datetime picker for the custom field value" do
        expect(rendered).to have_element "opce-basic-single-datetime-picker", "data-name": field_name.to_json
      end

      it "renders the picker as wide as the other text fields" do
        expect(rendered).to have_css "opce-basic-single-datetime-picker.form--text-field-container"
      end

      it "passes on whether the field is required" do
        expect(rendered).to have_element "opce-basic-single-datetime-picker",
                                         "data-required": custom_field.required?.to_json
      end

      context "with a submitted value" do
        let(:value) { "2026-10-01T12:30:00Z" }

        it "passes the value" do
          expect(rendered).to have_element "opce-basic-single-datetime-picker", "data-value": value.to_json
        end
      end
    end

    context "with a list custom field" do
      subject(:rendered) do
        Capybara.string(helper.custom_field_tag_for_bulk_edit("work_package", custom_field.reload, nil, nil))
      end

      shared_examples "a bulk-clearable list" do
        it "offers to clear the value" do
          expect(rendered).to have_select(with_options: ["(No change)", "none"])
        end

        context "when required" do
          before { custom_field.update!(is_required: true) }

          it "offers no way to clear it" do
            expect(rendered).to have_no_select(with_options: ["none"])
          end
        end
      end

      context "when it may nest but holds no nested items" do
        let(:custom_field) { create(:wp_custom_field, :hierarchy, possible_values: ["Design / UX"]) }

        it_behaves_like "a bulk-clearable list"

        it "lists its items by their label" do
          expect(rendered).to have_select(with_options: ["Design / UX"])
        end
      end

      context "when it holds nested items", with_ee: %i[custom_field_hierarchies] do
        let(:custom_field) do
          create(:wp_custom_field, :hierarchy, possible_values: ["Laptop"]).tap do |field|
            CustomFields::Hierarchy::HierarchicalItemService.new
              .insert_item(contract_class: CustomFields::Hierarchy::InsertHierarchyItemContract,
                           parent: field.possible_values.first, label: "MacBook")
          end
        end

        it_behaves_like "a bulk-clearable list"
      end
    end
  end
end
