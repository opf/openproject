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

      def initialize(custom_field)
        validation = ServiceInitializationContract.new.call(field_format: custom_field.field_format)
        raise ArgumentError, "Invalid custom field: #{validation.errors(full: true).to_h}" if validation.failure?

        @custom_field = custom_field
      end

      def generate_root
        CustomFields::Hierarchy::GenerateRootContract
          .new
          .call(hierarchy_root: @custom_field.hierarchy_root)
          .to_monad
          .bind { create_root_item }
      end

      def insert_item(parent:, label:, short: nil)
        CustomFields::Hierarchy::InsertItemContract
          .new
          .call({ parent:, label:, short: }.compact)
          .to_monad
          .bind { |validation| create_child_item(validation:) }
      end

      def update_item(item:, label: nil, short: nil)
        CustomFields::Hierarchy::UpdateItemContract
          .new
          .call({ item:, label:, short: }.compact)
          .to_monad
          .fmap { |attributes| update_item_attributes(item:, attributes:) }
      end

      def delete_branch(item:)
        return Failure(:item_is_root) if item.root?

        item.destroy ? Success() : Failure(item.errors)
      end

      def get_branch(item:)
        Success(item.ancestors.reverse)
      end

      def move_item(item:, new_parent:, sort_order:)
        # Move with all the children
        raise NotImplementedError
      end

      def reorder_item(item:, new_sort_order:)
        # move it around. Check closure_tree
        raise NotImplementedError
      end

      def soft_delete_item(item)
        # Soft delete the item and children?
        raise NotImplementedError
      end

      private

      def create_root_item
        item = CustomField::Hierarchy::Item.create(custom_field: @custom_field)
        return Failure(item.errors) unless item.persisted?

        Success(item)
      end

      def create_child_item(validation:)
        item = validation[:parent].children.create(label: validation[:label], short: validation[:short])
        return Failure(item.errors) unless item.persisted?

        Success(item)
      end

      def update_item_attributes(item:, attributes:)
        item.update(label: attributes[:label], short: attributes[:short])

        item.errors.empty? ? Success(item) : Failure(item.errors)
      end
    end
  end
end
