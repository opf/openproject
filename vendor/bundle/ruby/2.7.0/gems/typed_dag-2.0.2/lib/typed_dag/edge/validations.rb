module TypedDag::Edge
  module Validations
    extend ActiveSupport::Concern

    included do
      validates_uniqueness_of :from,
                              scope: [:to],
                              conditions: -> {
                                where.not("#{_dag_options.type_columns.join(' + ')} > 1")
                              }

      validate :no_circular_dependency

      private

      def no_circular_dependency
        # Disregard self in case one wants to inverse the edge's direction.
        # If the edge has not been persisted yet, AR will turn
        #   where.not(id: id)
        # into
        #   WHERE id IS NOT NULL
        # which is ok.
        if self
           .class
           .of_from_and_to(send(_dag_options.to_column),
                           send(_dag_options.from_column))
           .where
           .not(id: id)
           .exists?
          errors.add :base, :'typed_dag.circular_dependency'
        end
      end
    end
  end
end
