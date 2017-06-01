module API
  module Utilities
    class QueryFiltersNameConverterContext
      def initialize(query_class = Query)
        self.query_class = query_class
      end

      def respond_to?(method_name, include_private = false)
        query_class.registered_filters.map(&:key).include?(method_name.to_sym) || super
      end

      attr_accessor :query_class
    end
  end
end
