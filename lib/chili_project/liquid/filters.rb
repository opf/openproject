module ChiliProject
  module Liquid
    module Filters
      def default(input, default)
        input.to_s.strip.present? ? input : default
      end

      def strip(input)
        input.to_s.strip
      end
    end

    Template.register_filter(Filters)
  end
end
