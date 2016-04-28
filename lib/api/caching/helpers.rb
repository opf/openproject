module API
  module Caching
    module Helpers
      def with_etag!(key)
        etag = %(W/"#{::Digest::SHA1.hexdigest(key.to_s)}")
        error!('Not Modified'.freeze, 304) if headers['If-None-Match'.freeze] == etag

        header 'ETag'.freeze, etag
      end

      ##
      # Store a represented object in its JSON representation
      def cache(key, args = {})
        # Save serialization since we're only dealing with strings here
        args[:raw] = true

        json = Rails.cache.fetch(key, args) {
          result = yield
          result.to_json
        }

        ::API::Caching::StoredRepresenter.new json
      end
    end
  end
end
