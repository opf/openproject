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
        acts_as_nested_set :scope => 'root_id', :dependent => :destroy
        after_save :update_nested_set_attributes

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
        if @parent_issue
          if !Setting.cross_project_issue_relations? && @parent_issue.project_id != self.project_id
            errors.add :parent_issue_id, :not_a_valid_parent
          elsif !new_record?
            # moving an existing issue
            if @parent_issue.root_id != root_id
              # we can always move to another tree
            elsif move_possible?(@parent_issue)
              # move accepted inside tree
            else
              errors.add :parent_issue_id, :not_a_valid_parent
            end
          end
        end
      end

      def parent_issue_id=(arg)
        parent_issue_id = arg.blank? ? nil : arg.to_i
        if parent_issue_id && @parent_issue = self.class.find_by_id(parent_issue_id)
          journal_changes["parent_id"] = [self.parent_id, @parent_issue.id]
          @parent_issue.id
        else
          @parent_issue = nil
          journal_changes["parent_id"] = [self.parent_id, nil]
          nil
        end
      end

      def parent_issue_id
        if instance_variable_defined? :@parent_issue
          @parent_issue.nil? ? nil : @parent_issue.id
        else
          parent_id
        end
      end

      private

      def update_nested_set_attributes
        if root_id.nil?
          set_initial_root_id
        elsif parent_issue_id != parent_id
          update_existing_tree_node_attributes
        end
        remove_instance_variable(:@parent_issue) if instance_variable_defined?(:@parent_issue)
      end

      def set_initial_root_id
        self.root_id = (@parent_issue.nil? ? id : @parent_issue.root_id)
        set_default_left_and_right
        self.class.update_all("root_id = #{root_id}, lft = #{lft}, rgt = #{rgt}", ["id = ?", id])
        if @parent_issue
          move_to_child_of(@parent_issue)
        end
        reload
      end

      def move_in_tree(new_parent)
        if new_parent && new_parent.root_id == root_id
          # inside the same tree
          move_to_child_of(new_parent)
        else
          # to another tree
          unless root?
            move_to_right_of(root)
            reload
          end
          old_root_id = root_id
          self.root_id = (new_parent.nil? ? id : new_parent.root_id )
          target_maxright = nested_set_scope.maximum(right_column_name) || 0
          offset = target_maxright + 1 - lft

          self.class.update_all("root_id = #{root_id}, lft = lft + #{offset}, rgt = rgt + #{offset}",
                           ["root_id = ? AND lft >= ? AND rgt <= ? ", old_root_id, lft, rgt])
          self[left_column_name] = lft + offset
          self[right_column_name] = rgt + offset
          if new_parent
            move_to_child_of(new_parent)
          end
        end

        reload
      end

      def update_existing_tree_node_attributes
        former_parent_id = parent_id
        # moving an existing issue

        move_in_tree(@parent_issue)

        # delete invalid relations of all descendants
        self_and_descendants.each do |issue|
          issue.relations.each do |relation|
            relation.destroy unless relation.valid?
          end
        end

        # update former parent
        recalculate_attributes_for(former_parent_id) if former_parent_id
      end
    end
  end
end
