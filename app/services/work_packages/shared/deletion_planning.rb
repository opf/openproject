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

module WorkPackages
  module Shared
    # Splits the descendants of the work packages about to be deleted into those
    #  - that the user may see and delete, so they go with their root
    #  - and the rest, which survive and only lose their parent
    #
    # WorkPackages::DeleteService and the delete dialogs both use this module
    # to preview what will happen, and to find the work packages to be deleted.
    module DeletionPlanning
      def deleted_descendants
        deletion_partition[:deleted]
      end

      def deleted_descendants_under(root)
        deletion_partition[:deleted_by_root][root.id] || []
      end

      def unlinked_descendants
        deletion_partition[:unlinked]
      end

      def unlinked_descendants?
        unlinked_descendants.any?
      end

      def visible_unlinked_descendants
        @visible_unlinked_descendants ||=
          unlinked_descendants.select { |descendant| visible_descendant_ids.include?(descendant.id) }
      end

      def hidden_unlinked_count
        unlinked_descendants.size - visible_unlinked_descendants.size
      end

      private

      # include_descendants? is supplied by the includer. When false, every descendant is detached instead of deleted.
      # Unlinking a survivor is a side effect of the deletion, so this deliberately does not consider the
      # "manage_subtasks" permission.
      def deleted_with_roots?(descendant)
        include_descendants? && visible_descendant_ids.include?(descendant.id) && deletable?(descendant)
      end

      def deletable?(descendant)
        descendant.project && deletion_user.allowed_in_project?(:delete_work_packages, descendant.project)
      end

      def deletion_root_ids
        @deletion_root_ids ||= deletion_roots.map(&:id)
      end

      def descendants_of_deletion_roots
        @descendants_of_deletion_roots ||= WorkPackage
          .where(id: descendant_ids_of_deletion_roots)
          .includes(:project, :type, :status)
          .order(:id)
          .to_a
      end

      def descendant_ids_of_deletion_roots
        @descendant_ids_of_deletion_roots ||= WorkPackageHierarchy
          .where(ancestor_id: deletion_root_ids)
          .where("generations > 0")
          .distinct
          .pluck(:descendant_id) - deletion_root_ids
      end

      def visible_descendant_ids
        @visible_descendant_ids ||= WorkPackage
          .where(id: descendant_ids_of_deletion_roots)
          .visible(deletion_user)
          .pluck(:id)
          .to_set
      end

      def deletion_partition
        @deletion_partition ||= begin
          partition = { deleted: [], unlinked: [], deleted_by_root: {} }
          queue = deletion_root_ids.flat_map { |root_id| children_to_visit(root_id, root_id) }

          until queue.empty?
            root_id, descendant = queue.shift

            if deleted_with_roots?(descendant)
              record_deleted(partition, descendant, root_id)
              queue.concat(children_to_visit(descendant.id, root_id))
            else
              partition[:unlinked] << descendant
            end
          end

          partition
        end
      end

      def record_deleted(partition, descendant, root_id)
        partition[:deleted] << descendant
        (partition[:deleted_by_root][root_id] ||= []) << descendant
      end

      def children_to_visit(parent_id, root_id)
        descendants_by_parent[parent_id].to_a.map { |descendant| [root_id, descendant] }
      end

      def descendants_by_parent
        @descendants_by_parent ||= descendants_of_deletion_roots.group_by(&:parent_id)
      end
    end
  end
end
