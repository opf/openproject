module TypedDag::Edge
  module ClassMethods
    extend ActiveSupport::Concern

    class_methods do
      def _dag_options
        TypedDag::Configuration[self]
      end
    end

    included do
      def self.with_type_columns_not(column_requirements)
        where
          .not(column_requirements)
          .with_type_columns_0(_dag_options.type_columns - column_requirements.keys)
      end

      def self.with_type_columns(column_requirements)
        where(column_requirements)
          .with_type_columns_0(_dag_options.type_columns - column_requirements.keys)
      end

      def self.with_type_columns_0(columns)
        requirements = columns.map { |column| [column, 0] }.to_h

        where(requirements)
      end

      def self.of_from_and_to(from, to)
        where(_dag_options.from_column => from,
              _dag_options.to_column => to)
      end

      def self.direct
        where("#{_dag_options.type_columns.join(' + ')} = 1")
      end

      def self.non_reflexive
        where("#{_dag_options.type_columns.join(' + ')} > 0")
      end

      _dag_options.types.each do |key, _config|
        define_singleton_method :"#{key}" do
          with_type_columns_not(key => 0)
        end

        define_singleton_method :"non_#{key}" do
          where(key => 0)
        end
      end
    end
  end
end
