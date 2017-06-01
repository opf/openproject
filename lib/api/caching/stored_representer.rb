module API
  module Caching
    class StoredRepresenter
      def initialize(json)
        @json = json
      end

      def to_json
        @json
      end
    end
  end
end
