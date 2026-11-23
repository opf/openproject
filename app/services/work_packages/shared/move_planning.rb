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

module WorkPackages
  module Shared
    # Previews, before anything is actually saved, which descendants of the work
    # package(s) being moved the user may see and move versus which would be left
    # behind. WorkPackages::UpdateDependentContract is what actually enforces this
    # per descendant when the move is saved; this module exists for callers that need
    # to know the answer upfront: the move dialogs (to decide what to show), and
    # WorkPackages::UpdateContract (to reject the whole move outright when cross-project
    # relations are disabled and something would otherwise get left behind).
    #
    # Each descendant is judged on its own, by its own visibility and permission, not
    # by whether its own parent is moving too. A visible grandchild can therefore count
    # as movable even when its own (hidden) parent would stay behind; the user could
    # have moved that grandchild on its own anyway, so nothing is gained by holding it
    # back.
    module MovePlanning
      def has_visible_descendants?
        visible_descendant_ids.any?
      end

      def immovable_descendants
        descendants_of_move_roots.reject { |descendant| movable?(descendant) }
      end

      private

      def movable?(descendant)
        descendant.project &&
          visible_descendant_ids.include?(descendant.id) &&
          move_user.allowed_in_project?(:move_work_packages, descendant.project)
      end

      def move_root_ids
        @move_root_ids ||= move_roots.map(&:id)
      end

      def descendants_of_move_roots
        @descendants_of_move_roots ||= WorkPackage
          .where(id: descendant_ids_of_move_roots)
          .includes(:project)
          .to_a
      end

      def descendant_ids_of_move_roots
        @descendant_ids_of_move_roots ||= WorkPackageHierarchy
          .where(ancestor_id: move_root_ids)
          .where("generations > 0")
          .distinct
          .pluck(:descendant_id) - move_root_ids
      end

      def visible_descendant_ids
        @visible_descendant_ids ||= WorkPackage
          .where(id: descendant_ids_of_move_roots)
          .visible(move_user)
          .pluck(:id)
          .to_set
      end
    end
  end
end
