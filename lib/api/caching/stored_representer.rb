module API
  module Caching
    class StoredRepresenter
      def initialize(json)
        @json = json
      end

      def to_json(*_args)
        @json
      end
    end
  end
end
