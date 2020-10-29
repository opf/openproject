module TypedDag::Node
  module Associations
    extend ActiveSupport::Concern

    included do
      def self.dag_relations_association_lambda(column, depth = 0)
        -> {
          if depth != 0
            with_type_columns(column => depth)
          else
            with_type_columns_not(column => depth)
          end
        }
      end
      private_class_method :dag_relations_association_lambda

      has_many :relations_to,
               class_name: _dag_options.edge_class_name,
               foreign_key: _dag_options.from_column,
               dependent: :destroy

      has_many :relations_from,
               class_name: _dag_options.edge_class_name,
               foreign_key: _dag_options.to_column,
               dependent: :destroy

      _dag_options.types.each do |key, config|
        from_one_limited = config[:from].is_a?(Hash) && config[:from][:limit] == 1
        from_name = if config[:from].is_a?(Hash)
                      config[:from][:name]
                    else
                      config[:from]
                    end

        if from_one_limited
          has_one :"#{from_name}_relation",
                  dag_relations_association_lambda(key, 1),
                  class_name: _dag_options.edge_class_name,
                  foreign_key: _dag_options.to_column

          has_one from_name,
                  through: :"#{config[:from][:name]}_relation",
                  source: :from
        else
          has_many :"#{from_name}_relations",
                   dag_relations_association_lambda(key, 1),
                   class_name: _dag_options.edge_class_name,
                   foreign_key: _dag_options.to_column

          has_many from_name,
                   through: :"#{config[:from]}_relations",
                   source: :from,
                   dependent: :destroy
        end

        has_many :"#{config[:to]}_relations",
                 dag_relations_association_lambda(key, 1),
                 class_name: _dag_options.edge_class_name,
                 foreign_key: _dag_options.from_column

        has_many config[:to],
                 through: :"#{config[:to]}_relations",
                 source: :to

        has_many :"#{config[:all_to]}_relations",
                 dag_relations_association_lambda(key),
                 class_name: _dag_options.edge_class_name,
                 foreign_key: _dag_options.from_column

        has_many config[:all_to],
                 -> { distinct },
                 through: :"#{config[:all_to]}_relations",
                 source: :to

        has_many :"#{config[:all_from]}_relations",
                 dag_relations_association_lambda(key),
                 class_name: _dag_options.edge_class_name,
                 foreign_key: _dag_options.to_column

        has_many config[:all_from],
                 -> { distinct },
                 through: :"#{config[:all_from]}_relations",
                 source: :from
      end
    end
  end
end
