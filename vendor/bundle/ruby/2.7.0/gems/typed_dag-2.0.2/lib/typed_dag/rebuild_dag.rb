require 'typed_dag/sql'

module TypedDag::RebuildDag
  extend ActiveSupport::Concern

  class AttemptsExceededError < ::StandardError; end

  module ClassMethods
    def rebuild_dag!(max_attempts = 100)
      attempts = 0

      while !truncate_and_rebuild
        attempts += 1

        if attempts > max_attempts
          raise TypedDag::RebuildDag::AttemptsExceededError
        end
      end
    end

    private

    def truncate_and_rebuild
      _dag_options.edge_class.where("#{dag_helper.sum_of_type_columns} != 1").delete_all

      insert_transitive_relations

      build_closures
    end

    def build_closures
      inserted_rows = 1
      depth = 1

      while inserted_rows > 0
        inserted_rows = insert_closure_of_depth(depth)

        circle_results = get_circular(depth)

        unless circle_results.empty?
          remove_first_non_hierarchy_relation(circle_results)

          return false
        end

        depth += 1
      end

      true
    end

    def insert_closure_of_depth(depth)
      ActiveRecord::Base
        .connection
        .update TypedDag::Sql::InsertClosureOfDepth.sql(_dag_options, depth)
    end

    def get_circular(depth)
      ActiveRecord::Base
        .connection
        .select_values TypedDag::Sql::GetCircular.sql(_dag_options, depth)
    end

    def remove_first_non_hierarchy_relation(ids)
      ActiveRecord::Base
        .connection
        .execute TypedDag::Sql::RemoveInvalidRelation.sql(_dag_options, ids)
    end

    def insert_transitive_relations
      ActiveRecord::Base
        .connection
        .execute TypedDag::Sql::InsertReflexive.sql(_dag_options)
    end

    def dag_helper
      @helper ||= ::TypedDag::Sql::Helper.new(_dag_options)
    end
  end
end
