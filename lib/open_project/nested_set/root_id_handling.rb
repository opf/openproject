#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

# When included it adds the nested_set behaviour scoped by the attribute
# 'root_id'
#
# AwesomeNestedSet offers being scoped but does not handle inserting and
# updating with the scoped being set right. This module adds this.
#
# When being scoped, we no longer have one big set over the the entire table
# but a forest of sets instead.
#
# The idea of this extension is to always place the node in the correct set
# before standard awesome_nested_set does something. This is necessary as all
# awesome_nested_set methods check for the scope. Operations crossing the
# border of a set are not supported.
#
# One goal of this implementation is to avoid using move_to of
# awesome_nested_set so that the callbacks defined for move_to (:before_move,
# :after_move and :around_move) can safely be used.

module OpenProject::NestedSet
  module RootIdHandling
    def self.included(base)
      base.class_eval do
        after_save :manage_root_id
        acts_as_nested_set scope: 'root_id', dependent: :destroy

        # callback from awesome_nested_set
        # we call it by hand as we have to set the scope first
        skip_callback :create, :before, :set_default_left_and_right

        validate :validate_correct_parent

        include InstanceMethods
      end
    end

    module InstanceMethods
      # The number of "items" this issue spans in it's nested set
      #
      # A parent issue would span all of it's children + 1 left + 1 right (3)
      #
      #   |  parent |
      #   || child ||
      #
      # A child would span only itself (1)
      #
      #   |child|
      def nested_set_span
        rgt - lft
      end

      # Does this issue have children?
      def children?
        !leaf?
      end

      def validate_correct_parent
        # calling parent triggers the loading, so if we could not load one, the parent does not exist
        if parent_id && !parent
          errors.add :parent_id, :does_not_exist
        end
        # Checks parent issue assignment
        if parent
          if !Setting.cross_project_work_package_relations? && parent.project_id != project_id
            errors.add :parent_id, :cannot_be_in_another_project
          elsif !new_record?
            # moving an existing issue
            if parent.root_id != root_id
              # we can always move to another tree
            elsif move_possible?(parent)
              # move accepted inside tree
            else
              errors.add :parent_id, :not_a_valid_parent
            end
          end
        end
      end

      def parent_issue_id=(arg)
        warn '[DEPRECATION] No longer use parent_issue_id= - Use parent_id= instead.'

        self.parent_id = arg
      end

      def parent_issue_id
        warn '[DEPRECATION] No longer use parent_issue_id - Use parent_id instead.'

        parent_id
      end

      private

      def manage_root_id
        if root_id.nil? # new node
          initial_root_id
        elsif parent_id_changed?
          update_root_id
        end
      end

      # Places the node in the correct set upon creation.
      #
      # If a parent is provided on creation, the new node is placed in the set
      # of the parent. If no parent is provided, the new node defines it's own
      # set.
      def initial_root_id
        if parent
          self.root_id = parent.root_id
        else
          self.root_id = id
        end

        set_default_left_and_right
        persist_nested_set_attributes
      end

      # Places the node in a new set when necessary, so that it can be assigned
      # to a different parent.
      #
      # This method does nothing if the new parent is within the same set. The
      # method puts the node and all it's descendants in the set of the
      # designated parent if the designated parent is within another set.
      def update_root_id
        new_root_id = parent_id.nil? ? id : parent.root_id

        if new_root_id != root_id
          # as the following actions depend on the
          # node having current values, we reload them here
          reload_nested_set

          # and save them in order to be save between removing the node from
          # the set and fixing the former set's attributes
          old_root_id = root_id
          old_rgt = rgt

          moved_span = nested_set_span + 1

          move_subtree_to_new_set(new_root_id)
          correct_former_set_attributes(old_root_id, moved_span, old_rgt)
        end
      end

      def persist_nested_set_attributes
        self.class.update_all("root_id = #{root_id}, " +
                              "#{quoted_left_column_name} = #{lft}, " +
                              "#{quoted_right_column_name} = #{rgt}",
                              ['id = ?', id])
      end

      # Moves the node and all it's descendants to the set with the provided
      # root_id. It does not change the parent/child relationships.
      #
      # The subtree is placed to the right of the existing tree. All the
      # subtree's nodes receive new lft/rgt values that are higher than the
      # maximum rgt value of the set.
      #
      # The set than has two roots. As such this method should only be used
      # internally and the results should only be persisted for a short time.
      def move_subtree_to_new_set(new_root_id)
        old_root_id = root_id
        self.root_id = new_root_id

        target_maxright = nested_set_scope.maximum(right_column_name) || 0
        offset = target_maxright + 1 - lft

        # update all the sutree's nodes. The lft and right values are incremented
        # by the maximum of the set's right value.
        self.class.update_all("root_id = #{root_id}, " +
                              "#{quoted_left_column_name} = lft + #{offset}, " +
                              "#{quoted_right_column_name} = rgt + #{offset}",
                              ['root_id = ? AND ' +
                               "#{quoted_left_column_name} >= ? AND " +
                               "#{quoted_right_column_name} <= ? ", old_root_id, lft, rgt])

        self[left_column_name] = lft + offset
        self[right_column_name] = rgt + offset
      end

      # Update all nodes left and right values in the former set having a right
      # value larger than self's former right value.
      #
      # It calculates what will have to be subtracted from the left and right
      # values of the nodes in question.  Then it will always subtract this
      # value from the right value of every node.  It will only subtract the
      # value from the left value if the left value is larger than the removed
      # node's right value.
      #
      # Given a set:
      #       1*6
      #       / \
      #    2*3  4*5
      # for which the node with lft = 2 and rgt = 3 is self and was removed, the
      # resulting set will be:
      #       1*4
      #        |
      #       2*3

      def correct_former_set_attributes(old_root_id, removed_span, rgt_offset)
        # As every node takes two integers we can multiply the amount of
        # removed_nodes by 2 to calculate the value by which right and left
        # will have to be reduced.
        # removed_span = removed_nodes * 2

        self.class.update_all("#{quoted_right_column_name} = #{quoted_right_column_name} - #{removed_span}, " +
                              "#{quoted_left_column_name} = CASE " +
                                "WHEN #{quoted_left_column_name} > #{rgt_offset} " +
                                  "THEN #{quoted_left_column_name} - #{removed_span} " +
                                "ELSE #{quoted_left_column_name} END",
                              ["root_id = ? AND #{quoted_right_column_name} > ?", old_root_id, rgt_offset])
      end
    end
  end
end
