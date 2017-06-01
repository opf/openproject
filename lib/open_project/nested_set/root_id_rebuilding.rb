#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

# This module, when included, adds the ability to rebuild nested sets that are
# scoped by a root_id attribute.
#
# For the details of rebuilding see the included RebuildPatch.

module OpenProject::NestedSet
  module RootIdRebuilding
    def self.included(base)
      base.class_eval do
        include RebuildPatch

        # find all nodes
        # * having set a parent_id where the root_id
        #   1) points to self
        #   2) points to a node with a parent
        #   3) points to a node having a different root_id
        # * having not set a parent_id but a root_id
        # This unfortunately does not find the node with the id 3 in the following example
        # | id  | parent_id | root_id |
        # | 1   |           | 1       |
        # | 2   | 1         | 2       |
        # | 3   | 2         | 2       |
        # This would only be possible using recursive statements
        scope :invalid_root_ids, -> {
          where("(#{quoted_parent_column_full_name} IS NOT NULL AND " +
          "(#{quoted_table_name}.root_id = #{quoted_table_name}.id OR " +
          "(#{quoted_table_name}.root_id = parents.#{quoted_primary_key} AND parents.#{quoted_parent_column_name} IS NOT NULL) OR " +
          "(#{quoted_table_name}.root_id != parents.root_id))" +
          ') OR ' +
          "(#{quoted_table_name}.parent_id IS NULL AND #{quoted_table_name}.root_id != #{quoted_table_name}.#{quoted_primary_key})")
            .joins("LEFT OUTER JOIN #{quoted_table_name} parents ON parents.#{quoted_primary_key} = #{quoted_parent_column_full_name}")
        }

        extend ClassMethods
      end
    end

    module ClassMethods
      # method from acts_as_nested_set
      def valid?
        super && invalid_root_ids.empty?
      end

      def all_invalid
        (super + invalid_root_ids).uniq
      end

      def rebuild_silently!(roots = nil)
        invalid_root_ids_to_fix = if roots.is_a? Array
                                    roots
                                  elsif roots.present?
                                    [roots]
                                  else
                                    []
                                  end

        known_node_parents = Hash.new do |hash, ancestor_id|
          hash[ancestor_id] = find_by(id: ancestor_id)
        end

        fix_known_invalid_root_ids = lambda {
          invalid_nodes = invalid_root_ids

          invalid_roots = []

          invalid_nodes.each do |node|
            # At this point we can not trust nested set methods as the root_id is invalid.
            # Therefore we trust the parent_id to fetch all ancestors until we find the root
            ancestor = node

            while ancestor.parent_id
              ancestor = known_node_parents[ancestor.parent_id]
            end

            invalid_roots << ancestor

            if invalid_root_ids_to_fix.empty? || invalid_root_ids_to_fix.map(&:id).include?(ancestor.id)
              where(id: node.id).update_all(root_id: ancestor.id)
            end
          end

          fix_known_invalid_root_ids.call unless (invalid_roots.map(&:id) & invalid_root_ids_to_fix.map(&:id)).empty?
        }

        fix_known_invalid_root_ids.call

        super
      end
    end
  end
end
