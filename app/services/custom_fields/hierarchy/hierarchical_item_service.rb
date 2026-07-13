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

module CustomFields
  module Hierarchy
    class HierarchicalItemService
      include Dry::Monads[:result]

      # Generate the root item for the CustomField of type hierarchy
      # @param custom_field [CustomField] custom field of type hierarchy
      # @return [Success(CustomField::Hierarchy::Item), Failure(Dry::Validation::Result), Failure(ActiveModel::Errors)]
      def generate_root(custom_field)
        CustomFields::Hierarchy::GenerateRootContract
          .new
          .call(custom_field:)
          .to_monad
          .bind { |validation| create_root_item(validation[:custom_field]) }
      end

      # Insert a new node on the hierarchy tree at a desired position or at the end if no sort_order is passed.
      # @param contract_class [Class<CustomFields::Hierarchy::InsertListItemContract>, Class<CustomFields::Hierarchy::InsertWeightedItemContract>]
      #   the params validation contract class
      # @param parent [CustomField::Hierarchy::Item] the parent of the node
      # @param label [String] the node label/name that must be unique at the same tree level
      # @param short [String] an alias for the node
      # @param weight [Decimal] a numeric value for the node
      # @param before [Integer] the position where to prepend the item. If not set or the position does not exist,
      #   the item is inserted at the end.
      # @return [Success(CustomField::Hierarchy::Item), Failure(Dry::Validation::Result), Failure(ActiveModel::Errors)]
      def insert_item(contract_class:, parent:, label:, short: nil, weight: nil, before: nil)
        contract_class
          .new
          .call({ parent:, label:, short:, weight: })
          .to_monad
          .bind { |validation| create_child_item(validation:, before:) }
      end

      # Updates an item/node
      # @param contract_class [Class<CustomFields::Hierarchy::UpdateListItemContract>, Class<CustomFields::Hierarchy::UpdateWeightedItemContract>]
      #   the params validation contract class
      # @param item [CustomField::Hierarchy::Item] the item to be updated
      # @param label [String] the node label/name that must be unique at the same tree level
      # @param short [String] an alias for the node
      # @param weight [Decimal] a numeric value for the node
      # @return [Success(CustomField::Hierarchy::Item), Failure(Dry::Validation::Result), Failure(ActiveModel::Errors)]
      def update_item(contract_class:, item:, label: nil, short: nil, weight: nil)
        contract_class
          .new
          .call({ item:, label:, short:, weight: })
          .to_monad
          .bind { |attributes| update_item_attributes(item:, attributes:) }
      end

      # Delete an entire branch of the hierarchy/tree
      # @param item [CustomField::Hierarchy::Item] the parent of the node
      # @return [Success(CustomField::Hierarchy::Item), Failure(Symbol), Failure(ActiveModel::Errors)]
      def delete_branch(item:)
        return Failure(:item_is_root) if item.root?

        # We need to remember item_ids and custom_field and pass them separately
        # to update_calculated_values_for_hierarchy, as after destroying the
        # item, the methods will not return expected value (will return empty
        # list and nil)
        item_ids = item.self_and_descendant_ids
        custom_field = item.root&.custom_field

        ActiveRecord::Base.transaction do
          unless item.destroy
            raise ActiveRecord::Rollback
          end

          update_calculated_values_for_hierarchy(item_ids:, custom_field:)
          remove_assigned_custom_values(custom_field_id: custom_field.id, item_ids:)
        end

        if item.destroyed?
          Success()
        else
          Failure(item.errors)
        end
      end

      # Gets all nodes in a tree from the item/node back to the root.
      # Ordered from root to leaf
      # @param item [CustomField::Hierarchy::Item] the parent of the node
      # @return [Success(Array<CustomField::Hierarchy::Item>)]
      def get_branch(item:)
        Success(item.self_and_ancestors.reverse)
      end

      # Gets all nodes in a tree from the item/node back to the root without the item/node itself.
      # Ordered from root to leaf
      # @param item [CustomField::Hierarchy::Item] the parent of the node
      # @return [Success(Array<CustomField::Hierarchy::Item>)]
      def get_ancestors(item:)
        Success(item.ancestors.reverse)
      end

      # Gets all descendant nodes in a tree starting from the item/node.
      # @param item [CustomField::Hierarchy::Item] the node
      # @param include_self [Boolean] flag
      # @return [Success(Array<CustomField::Hierarchy::Item>)]
      def get_descendants(item:, include_self: true)
        result = item.self_and_descendants_preordered
        result = result.offset(1) unless include_self
        Success(result)
      end

      # Move an item/node to a new parent item/node
      # @param item [CustomField::Hierarchy::Item] the parent of the node
      # @param new_parent [CustomField::Hierarchy::Item] the new parent of the node
      # @return [Success(CustomField::Hierarchy::Item)]
      def move_item(item:, new_parent:)
        updated_item = new_parent.append_child(item)
        update_position_cache(new_parent.root)

        Success(updated_item)
      end

      # Reorder the item along its siblings.
      # @param item [CustomField::Hierarchy::Item] the parent of the node
      # @param new_sort_order [Integer] the new position of the node
      # @return [Success]
      def reorder_item(item:, new_sort_order:)
        return Success() if item.siblings.empty?

        new_sort_order = [0, new_sort_order.to_i].max
        return Success() if item.sort_order == new_sort_order

        update_item_order(item:, new_sort_order:)

        Success()
      end

      # Soft delete the item and children
      def soft_delete_item(item:)
        raise SubclassResponsibilityError
      end

      # Returns a hash of Item => { Item => [Item] }
      # @param item [CustomField::Hierarchy::Item] the start node
      # @param depth [Integer] limits the max depth of the hash. see {ClosureTree#hash_tree}
      # @return [Success({CustomField::Hierarchy::Item => Array, Hash})]
      def hashed_subtree(item:, depth:)
        if depth >= 0
          Success(item.hash_tree(limit_depth: depth + 1))
        else
          Success(item.hash_tree)
        end
      end

      # Checks if an item is a descendant of another node
      # @param item [CustomField::Hierarchy::Item] the item to be tested
      # @param parent [CustomField::Hierarchy::Item] the node to be checked against
      # @return [Success, Failure]
      def descendant_of?(item:, parent:)
        item.descendant_of?(parent) ? Success() : Failure()
      end

      private

      def create_root_item(custom_field)
        item = CustomField::Hierarchy::Item.create(custom_field: custom_field)
        return Failure(item.errors) if item.new_record?

        update_position_cache(item)
        Success(item)
      end

      def create_child_item(validation:, before:)
        item = CustomField::Hierarchy::Item.new(**validation.to_h.except(:parent))
        parent = validation[:parent]
        relative_sibling = parent.children.find_by(sort_order: before)

        if relative_sibling.present?
          relative_sibling.prepend_sibling(item)
        else
          parent.add_child(item)
        end

        return Failure(item.errors) if item.new_record?

        update_position_cache(item.root)
        Success(item.reload)
      end

      def remove_assigned_custom_values(custom_field_id:, item_ids:)
        CustomValue
          .where(custom_field_id:, value: item_ids)
          .delete_all
      rescue ActiveRecord::ActiveRecordError
        raise ActiveRecord::Rollback
      end

      def update_item_attributes(item:, attributes:)
        if item.update(label: attributes[:label], short: attributes[:short], weight: attributes[:weight])
          if item.weight_previously_changed?
            # Only changes to item are of interest, so no need to pass descendant ids
            update_calculated_values_for_hierarchy(item_ids: item.id, custom_field: item.root&.custom_field)
          end
          Success(item)
        else
          Failure(item.errors)
        end
      end

      # Recalculates Calculated Values in all projects that use the hierarchy's custom field
      def update_calculated_values_for_hierarchy(item_ids:, custom_field:)
        return unless custom_field&.field_format_weighted_item_list?

        custom_field.class.customized_class
                    .where(custom_values: custom_field.custom_values.where(value: item_ids))
                    .find_each do |customized|
          affected_cfs = customized.available_custom_fields.affected_calculated_fields([custom_field.id])

          customized.calculate_custom_fields(affected_cfs)
          customized.save if customized.changed_for_autosave?
        end
      end

      def update_item_order(item:, new_sort_order:)
        target_item = item.siblings.find_by(sort_order: new_sort_order)
        if target_item.present?
          target_item.prepend_sibling(item)
        else
          target_item = item.siblings.last
          target_item.append_sibling(item)
        end

        update_position_cache(item.root)
      end

      def update_position_cache(root)
        sql = <<-SQL.squish
          UPDATE hierarchical_items
          SET position_cache = subquery.position
          FROM (
            SELECT hi.id
                  , SUM((1 + COALESCE(anc.sort_order, 0)) *
                      POWER(count_max.total_descendants, count_max.max_gens - depths.generations)) AS position
            FROM hierarchical_items hi
                 INNER JOIN hierarchical_item_hierarchies hih ON hi.id = hih.descendant_id
                 JOIN hierarchical_item_hierarchies anc_h ON anc_h.descendant_id = hih.descendant_id
                 JOIN hierarchical_items anc ON anc.id = anc_h.ancestor_id
                 JOIN hierarchical_item_hierarchies depths ON depths.ancestor_id = #{root.id} AND depths.descendant_id = anc.id
               , (
                SELECT COUNT(1) AS total_descendants, MAX(generations) + 1 AS max_gens
                FROM hierarchical_items hi
                    INNER JOIN hierarchical_item_hierarchies hih ON hi.id = hih.ancestor_id
                WHERE ancestor_id = #{root.id}
                ) count_max
            WHERE hih.ancestor_id = #{root.id}
            GROUP BY hi.id) as subquery
          WHERE hierarchical_items.id = subquery.id;
        SQL

        OpenProject::Mutex.with_advisory_lock(CustomField::Hierarchy::Item, "position_update_anc_#{root.id}") do
          CustomField::Hierarchy::Item.connection.exec_update(sql)
        end
      end
    end
  end
end
