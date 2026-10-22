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

module WorkPackages::Relations
  extend ActiveSupport::Concern

  included do
    # All relations of the work package in both directions.
    # rubocop:disable Rails/InverseOf
    has_many :relations,
             ->(work_package) {
               unscope(:where)
                 .of_work_package(work_package)
             },
             dependent: :destroy do
      def visible(user = User.current)
        # The work_package_focus_scope in here is used to improve performance by reducing the number of
        # work packages that have to be checked for whether they are visible.
        # Since the method looks for relations on the current work package, only work packages
        # that are on either end of a relation with the current work package need to be considered.
        # The number should be quite small compared to the total number of work packages.

        # merge() method that we will be using below will be overriding all where conditions with the
        # ones coming in from the other relation. This is not what we want. We want to keep the old constraints
        # and add the new ones to it.
        old_constraints = arel.constraints

        work_package_focus_scope = Arel::Nodes::UnionAll.new(select(:from_id).arel, select(:to_id).arel)
        visible_relations = Relation.visible(user, work_package_focus_scope:)

        merge(visible_relations).where(old_constraints)
      end
    end
    # rubocop:enable Rails/InverseOf

    # Relations where the current work package follows another one.
    # In this case,
    #   * from is self.id
    #   * to is the followed work package
    has_many :follows_relations,
             -> { where(relation_type: Relation::TYPE_FOLLOWS) },
             class_name: "Relation",
             foreign_key: :from_id,
             autosave: true,
             dependent: :nullify,
             inverse_of: :from

    # Relations where the current work package is followed by another one.
    # In this case,
    #   * from is the following work package
    #   * to is self
    has_many :precedes_relations,
             -> { where(relation_type: Relation::TYPE_FOLLOWS) },
             class_name: "Relation",
             foreign_key: :to_id,
             autosave: true,
             dependent: :nullify,
             inverse_of: :to

    # Relations where the current work package blocks another one.
    # In this case,
    #   * from is self.id
    #   * to is the blocked work package
    has_many :blocks_relations,
             -> { where(relation_type: Relation::TYPE_BLOCKS) },
             class_name: "Relation",
             foreign_key: :from_id,
             autosave: true,
             dependent: :nullify,
             inverse_of: :from

    # Relations where the current work package duplicates another one.
    # In this case,
    #   * from is self.id
    #   * to is the duplicated work package
    has_many :duplicates_relations,
             -> { where(relation_type: Relation::TYPE_DUPLICATES) },
             class_name: "Relation",
             foreign_key: :from_id,
             autosave: true,
             dependent: :nullify,
             inverse_of: :from

    # Relations where the current work package is duplicated by another one.
    # In this case,
    #   * from is the duplicate work package
    #   * to is self
    has_many :duplicated_relations,
             -> { where(relation_type: Relation::TYPE_DUPLICATES) },
             class_name: "Relation",
             foreign_key: :to_id,
             autosave: true,
             dependent: :nullify,
             inverse_of: :to
  end
end
