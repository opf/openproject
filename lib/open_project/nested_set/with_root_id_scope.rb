#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module OpenProject::NestedSet
  module WithRootIdScope
    def self.included(base)
      base.class_eval do
        skip_callback :create, :before, :set_default_left_and_right
        after_save :manage_root_id
        acts_as_nested_set :scope => 'root_id', :dependent => :destroy

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
        # Checks parent issue assignment
        if parent
          if !Setting.cross_project_issue_relations? && parent.project_id != self.project_id
            errors.add :parent_id, :not_a_valid_parent
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
        warn "[DEPRECATION] No longer use parent_issue_id= - Use parent_id= instead."

        self.parent_id = arg
      end

      def parent_issue_id
        warn "[DEPRECATION] No longer use parent_issue_id - Use parent_id instead."

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

      def initial_root_id
        if parent_id
          self.root_id = parent.root_id
        else
          self.root_id = id
        end

        set_default_left_and_right
        persist_nested_set_attributes
      end

      def update_root_id
        new_root_id = parent_id.nil? ? id : parent.root_id

        if new_root_id != root_id
          # as the following actions depend on the
          # node having current values, we reload them here
          self.reload_nested_set

          # and save them in order to be save between removing the node from
          # the set and fixing the former set's attributes
          old_root_id = root_id
          old_rgt = rgt

          moved_span = nested_set_span + 1

          move_subtree_to_new_set(new_root_id, old_root_id)
          correct_former_set_attributes(old_root_id, moved_span, old_rgt)
        end
      end

      def persist_nested_set_attributes
        self.class.update_all("root_id = #{root_id}, lft = #{lft}, rgt = #{rgt}", ["id = ?", id])
      end

      def move_subtree_to_new_set(new_root_id, old_root_id)
        self.root_id = new_root_id

        target_maxright = nested_set_scope.maximum(right_column_name) || 0
        offset = target_maxright + 1 - lft

        self.class.update_all("root_id = #{root_id}, lft = lft + #{offset}, rgt = rgt + #{offset}",
                              ["root_id = ? AND lft >= ? AND rgt <= ? ", old_root_id, lft, rgt])

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
      # for wich the node with lft = 2 and rgt = 3 is self and was removed, the
      # resulting set will be:
      #       1*4
      #        |
      #       2*3

      def correct_former_set_attributes(old_root_id, removed_span, rgt_offset)
        # As every node takes two integers we can multiply the amount of
        # removed_nodes by 2 to calculate the value by which right and left
        # will have to be reduced.
        #removed_span = removed_nodes * 2

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
