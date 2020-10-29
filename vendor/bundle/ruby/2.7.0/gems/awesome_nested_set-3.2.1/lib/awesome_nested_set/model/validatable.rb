require 'awesome_nested_set/set_validator'

module CollectiveIdea
  module Acts
    module NestedSet
      module Model
        module Validatable

          def valid?
            left_and_rights_valid? && no_duplicates_for_columns? && all_roots_valid?
          end

          def left_and_rights_valid?
            SetValidator.new(self).valid?
          end

          def no_duplicates_for_columns?
            [quoted_left_column_full_name, quoted_right_column_full_name].all? do |column|
              # No duplicates
              select("#{scope_string}#{column}, COUNT(#{column}) as _count").
                group("#{scope_string}#{column}", quoted_primary_key_column_full_name).
                having("COUNT(#{column}) > 1").
                order(primary_column_name => :asc).
                first.nil?
            end
          end

          # Wrapper for each_root_valid? that can deal with scope.
          def all_roots_valid?
            if acts_as_nested_set_options[:scope]
              all_roots_valid_by_scope?(roots)
            else
              each_root_valid?(roots)
            end
          end

          def all_roots_valid_by_scope?(roots_to_validate)
            roots_grouped_by_scope(roots_to_validate).all? do |scope, grouped_roots|
              each_root_valid?(grouped_roots)
            end
          end

          def each_root_valid?(roots_to_validate)
            left_column = acts_as_nested_set_options[:left_column]
            reordered_roots = roots_reordered_by_column(roots_to_validate, left_column)
            left = right = 0
            reordered_roots.all? do |root|
              (root.left > left && root.right > right).tap do
                left = root.left
                right = root.right
              end
            end
          end

          private
          def roots_grouped_by_scope(roots_to_group)
            roots_to_group.group_by {|record|
              scope_column_names.collect {|col| record.send(col) }
            }
          end

          def roots_reordered_by_column(roots_to_reorder, column)
            if roots_to_reorder.respond_to?(:reorder) # ActiveRecord's relation
              roots_to_reorder.reorder(column)
            elsif roots_to_reorder.respond_to?(:sort) # Array
              roots_to_reorder.sort { |a, b| a.send(column) <=> b.send(column) }
            else
              roots_to_reorder
            end
          end

          def scope_string
            Array(acts_as_nested_set_options[:scope]).map do |c|
              connection.quote_column_name(c)
            end.push(nil).join(", ")
          end
        end
      end
    end
  end
end
