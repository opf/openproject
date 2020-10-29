module CollectiveIdea #:nodoc:
  module Acts #:nodoc:
    module NestedSet #:nodoc:
      class SetValidator

        def initialize(model)
          @model = model
          @scope = model.all
          @parent = arel_table.alias('parent')
        end

        def valid?
          query.count == 0
        end

        private

        attr_reader :model, :parent
        attr_accessor :scope

        delegate :parent_column_name, :primary_column_name, :primary_key, :left_column_name, :right_column_name, :arel_table,
          :quoted_table_name, :quoted_parent_column_full_name, :quoted_left_column_full_name, :quoted_right_column_full_name, :quoted_left_column_name, :quoted_right_column_name, :quoted_primary_column_name,
        :to => :model

        def query
          join_scope
          filter_scope
        end

        def join_scope
          join_arel = arel_table.join(parent, Arel::Nodes::OuterJoin).on(parent[primary_column_name].eq(arel_table[parent_column_name]))
          self.scope = scope.joins(join_arel.join_sources)
        end

        def filter_scope
          self.scope = scope.where(
                                   bound_is_null(left_column_name).
                                   or(bound_is_null(right_column_name)).
                                   or(left_bound_greater_than_right).
                                   or(parent_not_null.and(bounds_outside_parent))
                                   )
        end

        def bound_is_null(column_name)
          arel_table[column_name].eq(nil)
        end

        def left_bound_greater_than_right
          arel_table[left_column_name].gteq(arel_table[right_column_name])
        end

        def parent_not_null
          arel_table[parent_column_name].not_eq(nil)
        end

        def bounds_outside_parent
          arel_table[left_column_name].lteq(parent[left_column_name]).or(arel_table[right_column_name].gteq(parent[right_column_name]))
        end

      end
    end
  end
end
