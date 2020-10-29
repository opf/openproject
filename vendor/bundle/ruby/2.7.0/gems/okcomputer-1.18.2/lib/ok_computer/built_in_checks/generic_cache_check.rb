require "securerandom"

module OkComputer
  # Verifies that Rails can write to and read from its cache.
  class GenericCacheCheck < Check
    # Public: Check whether cache can be written to and read from
    def check
      test_value.tap do |value|
        Rails.cache.write(cache_key, value)
        if value == Rails.cache.read(cache_key)
          mark_message "Able to read and write via #{humanize_cache_store_name}"
        else
          mark_failure
          mark_message "Value read from the cache does not match the value written"
        end
      end
    rescue => error
      mark_failure
      mark_message "Connection failure: #{error}"
    end

    private

    # Private: Generate a unique value each time we check
    def test_value
      SecureRandom.hex
    end

    def cache_key
      "ock-generic-cache-check-#{Socket.gethostname}"
    end

    def humanize_cache_store_name
      name = if Rails.application.config.cache_store.is_a? Array
               Rails.application.config.cache_store[0]
             else
               Rails.application.config.cache_store
             end
      name.to_s.humanize
    end
  end
end
