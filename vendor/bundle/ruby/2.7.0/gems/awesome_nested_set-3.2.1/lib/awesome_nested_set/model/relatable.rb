module CollectiveIdea
  module Acts
    module NestedSet
      module Model
        module Relatable

          # Returns an collection of all parents
          def ancestors
            without_self self_and_ancestors
          end

          # Returns the collection of all parents and self
          def self_and_ancestors
            nested_set_scope.
              where(arel_table[left_column_name].lteq(left)).
              where(arel_table[right_column_name].gteq(right))
          end

          # Returns the collection of all children of the parent, except self
          def siblings
            without_self self_and_siblings
          end

          # Returns the collection of all children of the parent, including self
          def self_and_siblings
            nested_set_scope.children_of parent_id
          end

          # Returns a set of all of its nested children which do not have children
          def leaves
            descendants.where(
              "#{quoted_right_column_full_name} - #{quoted_left_column_full_name} = 1"
            )
          end

          # Returns the level of this object in the tree
          # root level is 0
          def level
            parent_id.nil? ? 0 : compute_level
          end

          # Returns a collection including all of its children and nested children
          def descendants
            without_self self_and_descendants
          end

          # Returns a collection including itself and all of its nested children
          def self_and_descendants
            # using _left_ for both sides here lets us benefit from an index on that column if one exists
            nested_set_scope.right_of(left).left_of(right)
          end

          def is_descendant_of?(other)
            within_node?(other, self) && same_scope?(other)
          end

          def is_or_is_descendant_of?(other)
            (other == self || within_node?(other, self)) && same_scope?(other)
          end

          def is_ancestor_of?(other)
            within_node?(self, other) && same_scope?(other)
          end

          def is_or_is_ancestor_of?(other)
            (self == other || within_node?(self, other)) && same_scope?(other)
          end

          # Check if other model is in the same scope
          def same_scope?(other)
            Array(acts_as_nested_set_options[:scope]).all? do |attr|
              self.send(attr) == other.send(attr)
            end
          end

          # Find the first sibling to the left
          def left_sibling
            siblings.left_of(left).last
          end

          # Find the first sibling to the right
          def right_sibling
            siblings.right_of(left).first
          end

          def root
            return self_and_ancestors.children_of(nil).first if persisted?

            if parent_id && current_parent = nested_set_scope.where(primary_column_name => parent_id).first!
              current_parent.root
            else
              self
            end
          end

          protected

          def compute_level
            node, nesting = determine_depth

            node == self ? ancestors.count : node.level + nesting
          end

          def determine_depth(node = self, nesting = 0)
            while (association = node.association(:parent)).loaded? && association.target
              nesting += 1
              node = node.parent
            end if node.respond_to?(:association)

            [node, nesting]
          end

          def within_node?(node, within)
            node.left < within.left && within.left < node.right
          end

        end
      end
    end
  end
end
