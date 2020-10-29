module TypedDag::Edge
  module ClosureMaintenance
    extend ActiveSupport::Concern

    included do
      before_create :set_count
      after_create :add_closures
      after_update :alter_closure
      after_destroy :truncate_closures

      private

      def set_count
        send("#{_dag_options.count_column}=", 1) if send(_dag_options.count_column).zero?
      end

      def add_closures
        return unless direct?

        self.class.connection.execute add_dag_closure_sql
      end

      def truncate_closures
        # The destroyed callback is also run for unpersisted records.
        # However, #persisted? will be false for destroyed records.
        return unless direct? && !new_record?

        update_and_delete_closure(self)
      end

      def truncate_closures_with_former_values
        former_values_relation = self.dup

        # rails 5.1 vs rails 5.0
        changes = if respond_to?(:saved_changes)
                    saved_changes.transform_values(&:first)
                  else
                    changed_attributes
                  end

        former_values_relation.attributes = changes

        update_and_delete_closure(former_values_relation)
      end

      def alter_closure
        return unless direct?

        truncate_closures_with_former_values
        add_closures
      end

      def update_and_delete_closure(relation)
        self.class.connection.execute truncate_dag_closure_sql(relation)
        self.class.connection.execute delete_zero_count_sql(relation)
      end

      def add_dag_closure_sql
        TypedDag::Sql::AddClosure.sql(self)
      end

      def truncate_dag_closure_sql(relation)
        TypedDag::Sql::TruncateClosure.sql(relation)
      end

      def delete_zero_count_sql(relation)
        TypedDag::Sql::DeleteZeroCount.sql(relation)
      end

      def from_id_value
        send(_dag_options.from_column)
      end

      def to_id_value
        send(_dag_options.to_column)
      end
    end
  end
end
