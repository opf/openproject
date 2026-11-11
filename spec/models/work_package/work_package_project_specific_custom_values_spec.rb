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

require "spec_helper"

RSpec.describe WorkPackage, "with project-specific custom field values" do
  shared_let(:type) { create(:type) }
  shared_let(:project) { create(:project, types: [type]) }

  let(:errors) { work_package.errors.symbols_for(custom_field.attribute_name.to_sym) }

  shared_examples "validating project-specific hierarchical items" do |factory|
    let(:custom_field) { create(factory, :project_specific_allowlist, types: [type]) }
    let(:allowed_item) { create(:hierarchy_item, parent: custom_field.hierarchy_root) }
    let(:other_item) { create(:hierarchy_item, parent: custom_field.hierarchy_root) }

    before do
      create(:project_specific_value_restriction, project:, hierarchy_item: allowed_item)
    end

    context "when creating a work package with an allowed item" do
      let(:work_package) { build(:work_package, project:, type:) }

      it "is valid" do
        work_package.custom_field_values = { custom_field.id => allowed_item.id.to_s }

        expect(work_package.valid?(:saving_custom_fields)).to be(true)
      end
    end

    context "when creating a work package with an item that is not allowed" do
      let(:work_package) { build(:work_package, project:, type:) }

      it "is invalid" do
        work_package.custom_field_values = { custom_field.id => other_item.id.to_s }
        work_package.valid?(:saving_custom_fields)

        expect(errors).to eq([:inclusion])
      end
    end

    context "with a stored item that is no longer allowed" do
      let(:work_package) do
        create(:work_package, project:, type:, custom_values: { custom_field.id => other_item.id.to_s }).reload
      end

      it "stays valid when all custom values are validated" do
        work_package.activate_custom_field_validations!

        expect(work_package.valid?(:saving_custom_fields)).to be(true)
      end

      it "is marked as no longer available in the project" do
        expect(work_package.custom_value_for(custom_field)).not_to be_available_in_project
      end
    end
  end

  context "for a list custom field" do
    let(:custom_field) do
      create(:list_wp_custom_field, :project_specific_allowlist, types: [type], possible_values: %w[A B C])
    end
    let(:option_a) { custom_field.custom_options.find_by!(value: "A") }
    let(:option_b) { custom_field.custom_options.find_by!(value: "B") }
    let(:option_c) { custom_field.custom_options.find_by!(value: "C") }

    before do
      create(:project_specific_value_restriction, project:, custom_option: option_a)
    end

    context "when creating a work package with an allowed option" do
      let(:work_package) { build(:work_package, project:, type:) }

      it "is valid" do
        work_package.custom_field_values = { custom_field.id => option_a.id.to_s }

        expect(work_package.valid?(:saving_custom_fields)).to be(true)
      end
    end

    context "when creating a work package with an option that is not allowed" do
      let(:work_package) { build(:work_package, project:, type:) }

      it "is invalid" do
        work_package.custom_field_values = { custom_field.id => option_b.id.to_s }
        work_package.valid?(:saving_custom_fields)

        expect(errors).to eq([:inclusion])
      end
    end

    context "with a stored option that is no longer allowed" do
      let(:work_package) do
        create(:work_package, project:, type:, custom_values: { custom_field.id => option_b.id.to_s }).reload
      end

      it "stays valid when all custom values are validated" do
        work_package.activate_custom_field_validations!

        expect(work_package.valid?(:saving_custom_fields)).to be(true)
      end

      it "is marked as no longer available in the project" do
        expect(work_package.custom_value_for(custom_field)).not_to be_available_in_project
      end

      it "is formatted as the placeholder" do
        expect(work_package.formatted_custom_value_for(custom_field)).to eq(I18n.t(:label_custom_value_no_longer_available))
      end

      it "is invalid when changing it to another option that is not allowed" do
        work_package.custom_field_values = { custom_field.id => option_c.id.to_s }
        work_package.activate_custom_field_validations!
        work_package.valid?(:saving_custom_fields)

        expect(errors).to eq([:inclusion])
      end
    end

    context "with a stored option that is allowed" do
      let(:work_package) do
        create(:work_package, project:, type:, custom_values: { custom_field.id => option_a.id.to_s }).reload
      end

      it "is available in the project" do
        expect(work_package.custom_value_for(custom_field)).to be_available_in_project
      end

      it "is formatted as the option" do
        expect(work_package.formatted_custom_value_for(custom_field)).to eq("A")
      end
    end

    describe "default values" do
      let(:work_package) { build(:work_package, project:, type:) }

      context "with an allowed default option" do
        let(:custom_field) do
          create(:list_wp_custom_field, :project_specific_allowlist,
                 types: [type], possible_values: %w[A B C], default_option: "A")
        end

        it "applies the default option" do
          expect(work_package.public_send(custom_field.attribute_getter)).to eq("A")
        end
      end

      context "with a default option that is not allowed" do
        let(:custom_field) do
          create(:list_wp_custom_field, :project_specific_allowlist,
                 types: [type], possible_values: %w[A B C], default_option: "B")
        end

        it "does not apply the default option" do
          expect(work_package.public_send(custom_field.attribute_getter)).to be_nil
        end
      end

      context "with default options of a multi-select field" do
        let(:custom_field) do
          create(:list_wp_custom_field, :project_specific_allowlist,
                 types: [type], possible_values: %w[A B C], multi_value: true, default_options: %w[A B])
        end

        it "only applies the allowed default options" do
          expect(work_package.public_send(custom_field.attribute_getter)).to eq(%w[A])
        end
      end
    end
  end

  context "for a hierarchy custom field", with_ee: [:custom_field_hierarchies] do
    it_behaves_like "validating project-specific hierarchical items", :hierarchy_wp_custom_field
  end

  context "for a weighted item list custom field", with_ee: [:weighted_item_lists] do
    it_behaves_like "validating project-specific hierarchical items", :weighted_item_list_wp_custom_field
  end
end
