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

      # Insert a new node on the hierarchy tree.
      # @param parent [CustomField::Hierarchy::Item] the parent of the node
      # @param label [String] the node label/name that must be unique at the same tree level
      # @param short [String] an alias for the node
      # @return [Success(CustomField::Hierarchy::Item), Failure(Dry::Validation::Result), Failure(ActiveModel::Errors)]
      def insert_item(parent:, label:, short: nil)
        CustomFields::Hierarchy::InsertItemContract
          .new
          .call({ parent:, label:, short: }.compact)
          .to_monad
          .bind { |validation| create_child_item(validation:) }
      end

      # Updates an item/node
      # @param item [CustomField::Hierarchy::Item] the item to be updated
      # @param label [String] the node label/name that must be unique at the same tree level
      # @param short [String] an alias for the node
      # @return [Success(CustomField::Hierarchy::Item), Failure(Dry::Validation::Result), Failure(ActiveModel::Errors)]
      def update_item(item:, label: nil, short: nil)
        CustomFields::Hierarchy::UpdateItemContract
          .new
          .call({ item:, label:, short: }.compact)
          .to_monad
          .bind { |attributes| update_item_attributes(item:, attributes:) }
      end

      # Delete an entire branch of the hierarchy/tree
      # @param item [CustomField::Hierarchy::Item] the parent of the node
      # @return [Success(CustomField::Hierarchy::Item), Failure(Symbol), Failure(ActiveModel::Errors)]
      def delete_branch(item:)
        return Failure(:item_is_root) if item.root?

        item.destroy ? Success() : Failure(item.errors)
      end

      # Gets all nodes in a tree from the item/node back to the root.
      # Ordered from root to leaf
      # @param item [CustomField::Hierarchy::Item] the parent of the node
      # @return [Success(Array<CustomField::Hierarchy::Item>)]
      def get_branch(item:)
        Success(item.ancestors.reverse)
      end

      # Move an item/node to a new parent item/node
      # @param item [CustomField::Hierarchy::Item] the parent of the node
      # @param new_parent [CustomField::Hierarchy::Item] the new parent of the node
      # @return [Success(CustomField::Hierarchy::Item)]
      def move_item(item:, new_parent:)
        Success(new_parent.append_child(item))
      end

      # Reorder the item along its siblings.
      # @param item [CustomField::Hierarchy::Item] the parent of the node
      # @param new_sort_order [Integer] the new parent of the node
      # @return [Success(CustomField::Hierarchy::Item)]
      def reorder_item(item:, new_sort_order:)
        old_item = item.siblings.where(sort_order: new_sort_order).first
        Success(old_item.prepend_sibling(item))
      end

      def soft_delete_item(item)
        # Soft delete the item and children
        raise NotImplementedError
      end

      private

      def create_root_item(custom_field)
        item = CustomField::Hierarchy::Item.create(custom_field: custom_field)
        return Failure(item.errors) if item.new_record?

        Success(item)
      end

      def create_child_item(validation:)
        item = validation[:parent].children.create(label: validation[:label], short: validation[:short])
        return Failure(item.errors) if item.new_record?

        Success(item)
      end

      def update_item_attributes(item:, attributes:)
        if item.update(label: attributes[:label], short: attributes[:short])
          Success(item)
        else
          Failure(item.errors)
        end
      end
    end
  end
end
