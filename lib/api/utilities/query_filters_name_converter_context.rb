module API
  module Utilities
    class QueryFiltersNameConverterContext
      def respond_to?(method_name, include_private = false)
        Query.registered_filters.map(&:key).include?(method_name.to_sym) || super
      end
    end
  end
end
