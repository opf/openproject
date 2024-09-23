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

require "typed_dag"

module Migration
  module MigrationUtils
    module TypedDag
      # rubocop:disable Rails/ApplicationRecord
      class WorkPackage < ActiveRecord::Base
        self.table_name = "work_packages"
      end

      class Relation < ActiveRecord::Base
        self.table_name = "relations"
      end
      # rubocop:enable Rails/ApplicationRecord

      def self.configure
        ::TypedDag::Configuration.set node_class_name: "Migration::MigrationUtils::TypedDag::WorkPackage",
                                      edge_class_name: "Migration::MigrationUtils::TypedDag::Relation",
                                      ancestor_column: "from_id",
                                      descendant_column: "to_id",
                                      types: {
                                        hierarchy: { from: { name: :parent, limit: 1 },
                                                     to: :children,
                                                     all_from: :ancestors,
                                                     all_to: :descendants },
                                        relates: { from: :related_to,
                                                   to: :relates_to,
                                                   all_from: :all_related_to,
                                                   all_to: :all_relates_to },
                                        duplicates: { from: :duplicates,
                                                      to: :duplicated,
                                                      all_from: :all_duplicates,
                                                      all_to: :all_duplicated },
                                        follows: { from: :precedes,
                                                   to: :follows,
                                                   all_from: :all_precedes,
                                                   all_to: :all_follows },
                                        blocks: { from: :blocked_by,
                                                  to: :blocks,
                                                  all_from: :all_blocked_by,
                                                  all_to: :all_blocks },
                                        includes: { from: :part_of,
                                                    to: :includes,
                                                    all_from: :all_part_of,
                                                    all_to: :all_includes },
                                        requires: { from: :required_by,
                                                    to: :requires,
                                                    all_from: :all_required_by,
                                                    all_to: :all_requires }
                                      }

        # Needs to be included after the configuration.
        WorkPackage.include(::TypedDag::Node)
        Relation.include(::TypedDag::Edge)
      end
    end
  end
end
