#  OpenProject is an open source project management software.
#  Copyright (C) the OpenProject GmbH
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License version 3.
#
#  OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
#  Copyright (C) 2006-2013 Jean-Philippe Lang
#  Copyright (C) 2010-2013 the ChiliProject Team
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
#  See COPYRIGHT and LICENSE files for more details.

module WorkPackages::Relations
  extend ActiveSupport::Concern

  included do
    # All relations of the work package in both directions.
    # Mostly used to have the relations destroyed upon destruction of the work package.
    # rubocop:disable Rails/InverseOf
    has_many :relations,
             ->(work_package) {
               unscope(:where)
                 .of_work_package(work_package)
             },
             dependent: :destroy
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
