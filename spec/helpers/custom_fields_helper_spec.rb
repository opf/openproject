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

    context "with project-specific values" do
      let(:project) { create(:project) }
      let(:other_project) { create(:project) }
      let(:option_texts) { rendered.all("option").map(&:text) }

      context "for a list custom field" do
        let(:custom_field) { create(:list_wp_custom_field, :project_specific_allowlist, possible_values: %w[A B]) }
        let(:option_a) { custom_field.custom_options.find_by!(value: "A") }
        let(:option_b) { custom_field.custom_options.find_by!(value: "B") }

        before do
          create(:project_specific_value_restriction, project:, custom_option: option_a)
          create(:project_specific_value_restriction, project:, custom_option: option_b)
          create(:project_specific_value_restriction, project: other_project, custom_option: option_a)
        end

        context "for a single project" do
          subject(:rendered) do
            Capybara.string(helper.custom_field_tag_for_bulk_edit("work_package", custom_field, project))
          end

          it "offers the options usable in the project" do
            expect(option_texts).to include("A", "B")
          end
        end

        context "for several projects" do
          subject(:rendered) do
            Capybara.string(
              helper.custom_field_tag_for_bulk_edit("work_package", custom_field, nil, usable_in: [project, other_project])
            )
          end

          it "only offers the options usable in all of them" do
            expect(option_texts).to include("A")
            expect(option_texts).not_to include("B")
          end
        end
      end

      context "for a hierarchy custom field", with_ee: [:custom_field_hierarchies] do
        let(:custom_field) { create(:hierarchy_wp_custom_field, :project_specific_allowlist) }
        let(:acme) { create(:hierarchy_item, parent: custom_field.hierarchy_root, label: "Acme") }
        let(:oscorp) { create(:hierarchy_item, parent: custom_field.hierarchy_root, label: "Oscorp") }

        subject(:rendered) do
          Capybara.string(
            helper.custom_field_tag_for_bulk_edit("work_package", custom_field, nil, usable_in: [project, other_project])
          )
        end

        before do
          create(:project_specific_value_restriction, project:, hierarchy_item: acme)
          create(:project_specific_value_restriction, project:, hierarchy_item: oscorp)
          create(:project_specific_value_restriction, project: other_project, hierarchy_item: acme)
        end

        it "only offers the items usable in all projects" do
          expect(option_texts).to include("Acme")
          expect(option_texts).not_to include("Oscorp")
        end
      end
    end
  end
end
