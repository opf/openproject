module TypedDag::Node
  module ClosureMaintenance
    extend ActiveSupport::Concern

    included do
      after_create :insert_reflexiv_relation

      def insert_reflexiv_relation
        _dag_options.edge_class.new(from: self, to: self).save(validate: false)
      end
    end
  end
end
