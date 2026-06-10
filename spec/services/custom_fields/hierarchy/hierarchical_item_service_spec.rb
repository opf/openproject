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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe CustomFields::Hierarchy::HierarchicalItemService, with_ee: [:custom_field_hierarchies] do
  subject(:service) { described_class.new }

  context "with ListItemContract" do
    let!(:custom_field) do
      create(:custom_field, field_format: "hierarchy", hierarchy_root: nil).tap do |cf|
        service.generate_root(cf).value!
        cf.reload
      end
    end
    let!(:contract_class) { CustomFields::Hierarchy::InsertListItemContract }

    let(:root) { custom_field.hierarchy_root }
    let!(:luke) { service.insert_item(contract_class:, parent: root, label: "luke", short: "LS").value! }
    let!(:mara) { service.insert_item(contract_class:, parent: luke, label: "mara").value! }

    describe "#generate_root" do
      # no tree needed for this section, but creation would fail due to non-existing root
      let!(:luke) { nil }
      let!(:mara) { nil }

      context "with valid hierarchy custom field" do
        let!(:custom_field) { create(:custom_field, field_format: "hierarchy", hierarchy_root: nil) }

        it "creates a root item successfully" do
          expect(service.generate_root(custom_field)).to be_success
        end
      end

      context "with invalid custom field type" do
        let!(:custom_field) { create(:custom_field, field_format: "text", hierarchy_root: nil) }

        it "requires a custom field of type hierarchy" do
          result = service.generate_root(custom_field).failure

          expect(result.errors[:custom_field]).to eq(["format 'text' is unsupported."])
        end
      end

      context "with persistence of hierarchy root fails" do
        let!(:custom_field) { create(:custom_field, field_format: "hierarchy", hierarchy_root: nil) }

        it "fails to create a root item" do
          allow(CustomField::Hierarchy::Item)
            .to receive(:create)
                  .and_return(instance_double(CustomField::Hierarchy::Item, new_record?: true, errors: "some errors"))

          result = service.generate_root(custom_field)
          expect(result).to be_failure
        end
      end

      context "with already existing hierarchy root" do
        it "fails to create a root item" do
          result = service.generate_root(custom_field)
          expect(result).to be_failure
        end
      end
    end

    describe "#insert_item" do
      let(:label) { "Child Item" }
      let(:short) { "Short Description" }

      context "with valid parameters" do
        it "inserts an item successfully without short" do
          result = service.insert_item(contract_class:, parent: luke, label:)

          expect(result).to be_success
          expect(luke.reload.children.count).to eq(2)
        end

        it "inserts an item successfully with short" do
          result = service.insert_item(contract_class:, parent: root, label:, short:)
          expect(result).to be_success
        end

        it "insert an item at a specific position" do
          leia = service.insert_item(contract_class:, parent: root, label: "leia").value!
          expect(root.reload.children).to contain_exactly(luke, leia)

          bob = service.insert_item(contract_class:, parent: root, label: "Bob", before: 1).value!
          expect(root.reload.children).to contain_exactly(luke, bob, leia)
        end

        it "updates the position_cache" do
          leia = service.insert_item(contract_class:, parent: root, label: "leia").value!
          expect(root.reload.position_cache).to eq(64)

          service.insert_item(contract_class:, parent: root, label: "Bob", before: 1).value!
          expect(leia.reload.position_cache).to eq(200)
        end
      end

      context "with invalid item" do
        it "fails to insert an item" do
          # child item won't be persisted if `add_child` is mocked
          allow(root).to receive(:add_child)

          result = service.insert_item(contract_class:, parent: root, label:, short:)
          expect(result).to be_failure
        end
      end
    end

    describe "#update_item" do
      context "with valid parameters" do
        it "updates the item with new attributes" do
          update_contract = CustomFields::Hierarchy::UpdateListItemContract
          result = service.update_item(contract_class: update_contract, item: luke, label: "Luke Skywalker", short: "LS")
          expect(result).to be_success
        end
      end

      context "with invalid parameters" do
        let!(:leia) { service.insert_item(contract_class:, parent: root, label: "leia").value! }

        it "refuses to update the item with new attributes" do
          update_contract = CustomFields::Hierarchy::UpdateListItemContract
          result = service.update_item(contract_class: update_contract, item: leia, label: "luke", short: "LS")
          expect(result).to be_failure

          errors = result.failure.errors
          expect(errors[:label]).to eq(["must be unique within the same hierarchy level."])
          expect(errors[:short]).to eq(["must be unique within the same hierarchy level."])
        end
      end
    end

    describe "#delete_branch" do
      context "with valid item to destroy" do
        it "deletes the entire branch" do
          result = service.delete_branch(item: luke)
          expect(result).to be_success
          expect(luke).to be_frozen
          expect(CustomField::Hierarchy::Item.count).to eq(1)
          expect(root.reload.children).to be_empty
        end

        it "updates the position_cache" do
          result = service.delete_branch(item: luke)

          expect(result).to be_success
          expect(root.reload.position_cache).to eq(27)
        end

        context "if the item or its descendants were assigned as a custom value" do
          let(:wp_type) { create(:type_task) }
          let(:project) { create(:project, types: [wp_type]) }
          let(:work_package) { create(:work_package, project:, type: wp_type) }
          let(:work_package_with_child_value) { create(:work_package, project:, type: wp_type) }
          let(:work_package_with_another_value) { create(:work_package, project:, type: wp_type) }
          let(:value_for_work_package) do
            create(:work_package_custom_value, custom_field:, customized: work_package, value: luke.id)
          end
          let(:value_for_work_package_with_child_value) do
            create(:work_package_custom_value, custom_field:, customized: work_package_with_child_value, value: mara.id)
          end
          let(:value_for_work_package_with_another_value) do
            create(:work_package_custom_value,
                   custom_field:,
                   customized: work_package_with_another_value,
                   value: leia.id)
          end

          let!(:custom_field) do
            create(:hierarchy_wp_custom_field, projects: [project], types: [wp_type], hierarchy_root: nil).tap do |cf|
              service.generate_root(cf).value!
              cf.reload
            end
          end
          let!(:leia) { service.insert_item(contract_class:, parent: root, label: "leia", short: "LO").value! }

          before do
            value_for_work_package
            value_for_work_package_with_child_value
            value_for_work_package_with_another_value
          end

          it "removes the custom values of the deleted item from the work package" do
            result = service.delete_branch(item: luke)

            expect(result).to be_success
            expect(work_package.reload.custom_value_for(custom_field).value).to be_nil
          end

          it "removes the custom values of descendants of the deleted item from the work package" do
            result = service.delete_branch(item: luke)

            expect(result).to be_success
            expect(work_package_with_child_value.reload.custom_value_for(custom_field).value).to be_nil
          end

          it "does not remove custom values of items that are unrelated" do
            result = service.delete_branch(item: luke)

            expect(result).to be_success
            expect(work_package_with_another_value.reload.custom_value_for(custom_field).value).to eq(leia.id.to_s)
          end
        end
      end

      context "with root item" do
        it "refuses to delete the item" do
          result = service.delete_branch(item: root)
          expect(result).to be_failure
        end
      end
    end

    describe "#get_branch" do
      context "with a non-root node" do
        it "returns all the ancestors to that item" do
          result = service.get_branch(item: mara)
          expect(result).to be_success

          ancestors = result.value!
          expect(ancestors.size).to eq(3)
          expect(ancestors).to contain_exactly(root, luke, mara)
          expect(ancestors.last).to eq(mara)
        end
      end

      context "with a root node" do
        it "returns a list with the root node" do
          result = service.get_branch(item: root)
          expect(result).to be_success
          expect(result.value!).to match_array(root)
        end
      end
    end

    describe "#get_ancestors" do
      context "with a non-root node" do
        it "returns all the ancestors to that item" do
          result = service.get_ancestors(item: mara)
          expect(result).to be_success

          ancestors = result.value!
          expect(ancestors.size).to eq(2)
          expect(ancestors).to contain_exactly(root, luke)
        end
      end

      context "with a root node" do
        it "returns a empty list" do
          result = service.get_ancestors(item: root)
          expect(result).to be_success
          expect(result.value!).to be_empty
        end
      end
    end

    describe "#get_descendants" do
      let!(:subitem) { service.insert_item(contract_class:, parent: mara, label: "Sub1").value! }
      let!(:subitem2) { service.insert_item(contract_class:, parent: mara, label: "sub two").value! }
      let!(:unrelated_subitem) { service.insert_item(contract_class:, parent: luke, label: "not related").value! }

      context "with a non-root node" do
        it "returns all the descendants to that item" do
          result = service.get_descendants(item: mara)
          expect(result).to be_success

          descendants = result.value!
          expect(descendants).to contain_exactly(mara, subitem, subitem2)
        end
      end

      context "with a leaf node" do
        it "returns just the leaf node" do
          result = service.get_descendants(item: subitem2)
          expect(result).to be_success
          expect(result.value!).to match_array(subitem2)
        end
      end

      context "when does not include self" do
        it "returns all descendants not including the item passed" do
          result = service.get_descendants(item: mara, include_self: false)
          expect(result).to be_success

          descendants = result.value!
          expect(descendants).to contain_exactly(subitem, subitem2)
        end
      end
    end

    describe "#move_item" do
      let(:lando) { service.insert_item(contract_class:, parent: root, label: "lando").value! }

      it "move the node to the new parent" do
        expect { service.move_item(item: mara, new_parent: lando) }.to change { mara.reload.ancestors.first }.to(lando)
      end

      it "all child nodes follow" do
        service.move_item(item: luke, new_parent: lando)

        expect(luke.reload.ancestors).to contain_exactly(root, lando)
        expect(mara.reload.ancestors).to contain_exactly(root, lando, luke)
      end

      it "updates the position_cache" do
        service.move_item(item: luke, new_parent: lando)

        preordered_descendants = root.reload.self_and_descendants_preordered.pluck(:label)
        expect(root.self_and_descendants.reorder(:position_cache).pluck(:label)).to eq(preordered_descendants)
      end
    end

    describe "#reorder_item" do
      let!(:lando) { service.insert_item(contract_class:, parent: root, label: "lando").value! }
      let!(:chewbacca) { service.insert_item(contract_class:, parent: root, label: "AWOOO").value! }

      it "reorders the item to the target position" do
        service.reorder_item(item: chewbacca, new_sort_order: 1)

        expect(luke.reload.sort_order).to eq(0)
        expect(chewbacca.reload.sort_order).to eq(1)
        expect(lando.reload.sort_order).to eq(2)
      end

      it "reorders the item even if sort order is a string" do
        service.reorder_item(item: chewbacca, new_sort_order: "1")

        expect(luke.reload.sort_order).to eq(0)
        expect(chewbacca.reload.sort_order).to eq(1)
        expect(lando.reload.sort_order).to eq(2)
      end

      it "reorders the item to the last position" do
        service.reorder_item(item: lando, new_sort_order: root.children.length)

        expect(luke.reload.sort_order).to eq(0)
        expect(chewbacca.reload.sort_order).to eq(1)
        expect(lando.reload.sort_order).to eq(2)
      end

      it "reorders the item to the first position" do
        service.reorder_item(item: chewbacca, new_sort_order: 0)

        expect(chewbacca.reload.sort_order).to eq(0)
        expect(luke.reload.sort_order).to eq(1)
        expect(lando.reload.sort_order).to eq(2)
      end

      it "does not reorder before first" do
        service.reorder_item(item: lando, new_sort_order: -10)

        expect(lando.reload.sort_order).to eq(0)
        expect(luke.reload.sort_order).to eq(1)
        expect(chewbacca.reload.sort_order).to eq(2)
      end

      it "does not reorder after last" do
        service.reorder_item(item: chewbacca, new_sort_order: 99)

        expect(luke.reload.sort_order).to eq(0)
        expect(lando.reload.sort_order).to eq(1)
        expect(chewbacca.reload.sort_order).to eq(2)
      end

      it "does not reorder when changing self" do
        service.reorder_item(item: lando, new_sort_order: lando.sort_order)

        expect(luke.reload.sort_order).to eq(0)
        expect(lando.reload.sort_order).to eq(1)
        expect(chewbacca.reload.sort_order).to eq(2)
      end

      it "updates the position_cache" do
        service.reorder_item(item: chewbacca, new_sort_order: 0)

        preordered_descendants = root.reload.self_and_descendants_preordered.pluck(:label)
        expect(root.self_and_descendants.reorder(:position_cache).pluck(:label)).to eq(preordered_descendants)
      end
    end

    describe "#hashed_subtree" do
      let!(:lando) { service.insert_item(contract_class:, parent: root, label: "lando").value! }
      let!(:chewbacca) { service.insert_item(contract_class:, parent: root, label: "AWOOO").value! }
      let!(:lowbacca) { service.insert_item(contract_class:, parent: chewbacca, label: "ARWWWW").value! }

      it "produces a hash version of the tree" do
        subtree = service.hashed_subtree(item: root, depth: -1)

        expect(subtree.value!).to be_a(Hash)
        expect(subtree.value![root].size).to eq(3)
        expect(subtree.value![root][lando]).to be_empty
        expect(subtree.value![root][chewbacca][lowbacca]).to be_empty
      end

      it "produces a hash version of a sub tree with limited depth" do
        subtree = service.hashed_subtree(item: chewbacca, depth: 0)

        expect(subtree.value!).to be_a(Hash)
        expect(subtree.value![chewbacca]).to be_empty
      end
    end
  end

  context "with weighted item list and calculated values", with_ee: %i[calculated_values weighted_item_lists] do
    current_user { create(:admin) }

    let!(:project_using_one) { create(:project) }
    let!(:project_using_two) { create(:project) }
    let!(:project_having_fields_enabled) { create(:project) }
    let!(:project_not_having_fields_enabled) { create(:project) }
    let!(:projects) { [project_using_one, project_using_two, project_having_fields_enabled] }
    let!(:custom_field) { create(:weighted_item_list_project_custom_field, projects:) }
    let!(:one) { create(:hierarchy_item, parent: custom_field.hierarchy_root, label: "One", weight: 1) }
    let!(:two) { create(:hierarchy_item, parent: custom_field.hierarchy_root, label: "Two", weight: 2) }
    let!(:calculated_value) do
      create(:calculated_value_project_custom_field,
             :skip_validations,
             projects:,
             formula: "{{cf_#{custom_field.id}}} * 2")
    end

    before do
      project_using_one.custom_values.create!(custom_field: custom_field, value: one.id)
      project_using_one.custom_values.create!(custom_field: calculated_value, value: "123")

      project_using_two.custom_values.create!(custom_field: custom_field, value: two.id)
      project_using_two.custom_values.create!(custom_field: calculated_value, value: "123")
    end

    describe "updating the weight of an item" do
      let!(:contract_class) { CustomFields::Hierarchy::UpdateWeightedItemContract }

      subject(:result) { service.update_item(contract_class:, item: one, label: one.label, weight: 42) }

      it "updates calculated values affected by the change" do
        expect(result).to be_success

        expect(project_using_one.custom_value_for(calculated_value)).to have_attributes(value: "84.0")
      end

      it "doesn't update calculated values unaffected by the change" do
        expect(result).to be_success

        expect(project_using_two.custom_value_for(calculated_value)).to have_attributes(value: "123")
        expect(project_having_fields_enabled.custom_values).to be_empty
        expect(project_having_fields_enabled.custom_values).to be_empty
      end
    end

    describe "deleting an item" do
      subject(:result) { service.delete_branch(item: one) }

      it "updates calculated values affected by the change" do
        expect(result).to be_success

        expect(project_using_one.custom_value_for(calculated_value)).to have_attributes(value: nil)
      end

      it "doesn't update calculated values unaffected by the change" do
        expect(result).to be_success

        expect(project_using_two.custom_value_for(calculated_value)).to have_attributes(value: "123")
        expect(project_having_fields_enabled.custom_values).to be_empty
        expect(project_having_fields_enabled.custom_values).to be_empty
      end
    end
  end
end
