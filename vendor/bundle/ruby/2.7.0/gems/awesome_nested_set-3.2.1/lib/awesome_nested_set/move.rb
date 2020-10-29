module CollectiveIdea #:nodoc:
  module Acts #:nodoc:
    module NestedSet #:nodoc:
      class Move
        attr_reader :target, :position, :instance

        def initialize(target, position, instance)
          @target = target
          @position = position
          @instance = instance
        end

        def move
          prevent_impossible_move

          bound, other_bound = get_boundaries

          # there would be no change
          return if bound == right || bound == left

          # we have defined the boundaries of two non-overlapping intervals,
          # so sorting puts both the intervals and their boundaries in order
          a, b, c, d = [left, right, bound, other_bound].sort

          lock_nodes_between! a, d

          nested_set_scope_without_default_scope.where(where_statement(a, d)).update_all(
            conditions(a, b, c, d)
          )
        end

        private

        delegate :left, :right, :left_column_name, :right_column_name,
                 :quoted_left_column_name, :quoted_right_column_name,
                 :quoted_parent_column_name, :parent_column_name, :nested_set_scope_without_default_scope,
                 :primary_column_name, :quoted_primary_column_name, :primary_id,
                 :to => :instance

        delegate :arel_table, :class, :to => :instance, :prefix => true
        delegate :base_class, :to => :instance_class, :prefix => :instance

        def where_statement(left_bound, right_bound)
          instance_arel_table[left_column_name].between(left_bound..right_bound).
            or(instance_arel_table[right_column_name].between(left_bound..right_bound))
        end

        # Before Arel 6, there was 'in' method, which was replaced
        # with 'between' in Arel 6 and now gives deprecation warnings
        # in verbose mode. This is patch to support rails 4.0 (Arel 4)
        # and 4.1 (Arel 5).
        module LegacyWhereStatementExt
          def where_statement(left_bound, right_bound)
            instance_arel_table[left_column_name].in(left_bound..right_bound).
            or(instance_arel_table[right_column_name].in(left_bound..right_bound))
          end
        end
        prepend LegacyWhereStatementExt unless Arel::Predications.method_defined?(:between)

        def conditions(a, b, c, d)
          _conditions = case_condition_for_direction(:quoted_left_column_name) +
                        case_condition_for_direction(:quoted_right_column_name) +
                        case_condition_for_parent

          # We want the record to be 'touched' if it timestamps.
          if @instance.respond_to?(:updated_at)
            _conditions << ", updated_at = :timestamp"
          end

          [
            _conditions,
            {
              :a => a, :b => b, :c => c, :d => d,
              :primary_id => instance.primary_id,
              :new_parent_id => new_parent_id,
              :timestamp => Time.now.utc
            }
          ]
        end

        def case_condition_for_direction(column_name)
          column = send(column_name)
          "#{column} = CASE " +
            "WHEN #{column} BETWEEN :a AND :b " +
            "THEN #{column} + :d - :b " +
            "WHEN #{column} BETWEEN :c AND :d " +
            "THEN #{column} + :a - :c " +
            "ELSE #{column} END, "
        end

        def case_condition_for_parent
          "#{quoted_parent_column_name} = CASE " +
            "WHEN #{quoted_primary_column_name} = :primary_id THEN :new_parent_id " +
            "ELSE #{quoted_parent_column_name} END"
        end

        def lock_nodes_between!(left_bound, right_bound)
          # select the rows in the model between a and d, and apply a lock
          instance_base_class.right_of(left_bound).left_of_right_side(right_bound).
                              select(primary_column_name).lock(true)
        end

        def root
          position == :root
        end

        def new_parent_id
          case position
          when :child then target.primary_id
          when :root  then nil
          else target[parent_column_name]
          end
        end

        def get_boundaries
          if (bound = target_bound) > right
            bound -= 1
            other_bound = right + 1
          else
            other_bound = left - 1
          end
          [bound, other_bound]
        end

        class ImpossibleMove < ActiveRecord::StatementInvalid
        end

        def prevent_impossible_move
          if !root && !instance.move_possible?(target)
            raise ImpossibleMove, "Impossible move, target node cannot be inside moved tree."
          end
        end

        def target_bound
          case position
          when :child then right(target)
          when :left  then left(target)
          when :right then right(target) + 1
          when :root  then nested_set_scope_without_default_scope.pluck(right_column_name).max + 1
          else raise ActiveRecord::ActiveRecordError, "Position should be :child, :left, :right or :root ('#{position}' received)."
          end
        end
      end
    end
  end
end
