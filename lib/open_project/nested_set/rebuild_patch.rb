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

# When included, it adds the ability to rebuild nested sets, thus fixing
# corrupted trees.
#
# AwesomeNestedSet has this functionality as well but it fixes the sets with
# running the callbacks defined in the model. This has two drawbacks:
#
# * It is prone to fail when a validation fails that has nothing to do with
# nested sets.
# * It is slow.
#
# The methods included are purely sql based. The code in here is partly copied
# over from awesome_nested_set's non sql methods.

module OpenProject::NestedSet::RebuildPatch
  def self.included(base)
    base.class_eval do
      scope :invalid_left_and_rights, -> {
        joins("LEFT OUTER JOIN #{quoted_table_name} AS parent ON " +
          "#{quoted_table_name}.#{quoted_parent_column_name} = parent.#{primary_key}")
          .where("#{quoted_table_name}.#{quoted_left_column_name} IS NULL OR " +
            "#{quoted_table_name}.#{quoted_right_column_name} IS NULL OR " +
            "#{quoted_table_name}.#{quoted_left_column_name} >= " +
            "#{quoted_table_name}.#{quoted_right_column_name} OR " +
            "(#{quoted_table_name}.#{quoted_parent_column_name} IS NOT NULL AND " +
            "(#{quoted_table_name}.#{quoted_left_column_name} <= parent.#{quoted_left_column_name} OR " +
            "#{quoted_table_name}.#{quoted_right_column_name} >= parent.#{quoted_right_column_name}))")
      }

      scope :invalid_duplicates_in_columns, -> {
        scope_string = Array(acts_as_nested_set_options[:scope]).map { |c|
          "#{quoted_table_name}.#{connection.quote_column_name(c)} = duplicates.#{connection.quote_column_name(c)}"
        }.join(' AND ')

        scope_string = scope_string.size > 0 ? scope_string + ' AND ' : ''

        joins("LEFT OUTER JOIN #{quoted_table_name} AS duplicates ON " +
          scope_string +
          "#{quoted_table_name}.#{primary_key} != duplicates.#{primary_key} AND " +
          "(#{quoted_table_name}.#{quoted_left_column_name} = duplicates.#{quoted_left_column_name} OR " +
          "#{quoted_table_name}.#{quoted_right_column_name} = duplicates.#{quoted_right_column_name})")
          .where("duplicates.#{primary_key} IS NOT NULL")
      }

      scope :invalid_roots, -> {
        scope_string = Array(acts_as_nested_set_options[:scope]).map { |c|
          "#{quoted_table_name}.#{connection.quote_column_name(c)} = other.#{connection.quote_column_name(c)}"
        }.join(' AND ')

        scope_string = scope_string.size > 0 ? scope_string + ' AND ' : ''

        joins("LEFT OUTER JOIN #{quoted_table_name} AS other ON " +
          "#{quoted_table_name}.#{primary_key} != other.#{primary_key} AND " +
          "#{quoted_table_name}.#{parent_column_name} IS NULL AND " +
          "other.#{parent_column_name} IS NULL AND " +
          scope_string +
          "#{quoted_table_name}.#{quoted_left_column_name} <= other.#{quoted_right_column_name} AND " +
          "#{quoted_table_name}.#{quoted_right_column_name} >= other.#{quoted_left_column_name}")
          .where("other.#{primary_key} IS NOT NULL")
          .order(quoted_left_column_name)
      }

      extend(ClassMethods)
    end
  end

  module ClassMethods
    def selectively_rebuild_silently!
      all_invalid

      invalid_roots, invalid_descendants = all_invalid.partition { |node| node.send(parent_column_name).nil? }

      while invalid_descendants.size > 0
        invalid_descendants_parents = invalid_descendants.map { |node| find(node.send(parent_column_name)) }

        new_invalid_roots, invalid_descendants = invalid_descendants_parents.partition { |node| node.send(parent_column_name).nil? }

        invalid_roots += new_invalid_roots

        invalid_descendants.uniq!
      end

      rebuild_silently!(invalid_roots.uniq)
    end

    # Rebuilds the left & rights if unset or invalid.  Also very useful for converting from acts_as_tree.
    # Very similar to original nested_set implementation but uses update_all so that callbacks are not triggered
    def rebuild_silently!(roots = nil)
      # Don't rebuild a valid tree.
      return true if valid?

      scope = lambda { |_node| }
      if acts_as_nested_set_options[:scope]
        scope = lambda { |node|
          scope_column_names.inject('') {|str, column_name|
            str << "AND #{connection.quote_column_name(column_name)} = #{connection.quote(node.send(column_name.to_sym))} "
          }
        }
      end

      # setup index

      indices = Hash.new do |h, k|
        h[k] = 0
      end

      set_left_and_rights = lambda { |node|
        # set left
        node[left_column_name] = indices[scope.call(node)] += 1
        # find
        children = where(["#{quoted_parent_column_name} = ? #{scope.call(node)}", node])
                   .order([quoted_left_column_name,
                           quoted_right_column_name,
                           acts_as_nested_set_options[:order]].compact.join(', '))

        children.each do |n| set_left_and_rights.call(n) end

        # set right
        node[right_column_name] = indices[scope.call(node)] += 1

        changes = node.changes.inject({}) { |hash, (attribute, _values)|
          hash[attribute] = node.send(attribute.to_s)
          hash
        }

        where(id: node.id).update_all(changes) unless changes.empty?
      }

      # Find root node(s)
      # or take provided
      root_nodes = if roots.is_a? Array
                     roots
                   elsif roots.present?
                     [roots]
                   else
                     where("#{quoted_parent_column_name} IS NULL")
                     .order([quoted_left_column_name,
                             quoted_right_column_name,
                             acts_as_nested_set_options[:order]].compact.join(', '))
                   end

      root_nodes.each do |root_node|
        set_left_and_rights.call(root_node)
      end
    end

    def all_invalid
      invalid = invalid_roots + invalid_left_and_rights + invalid_duplicates_in_columns
      invalid.uniq
    end
  end
end
