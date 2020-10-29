module OkComputer
  # Verifies that the Rails cache is set up and can speak with Memcached
  # running on the given host (defaults to local).
  class CacheCheck < Check
    attr_accessor :host

    def initialize(host=Socket.gethostname)
      self.host = host
    end

    # Public: Check whether the cache is active
    def check
      mark_message "Cache is available (#{stats})"
    rescue ConnectionFailed => e
      mark_failure
      mark_message "Error: '#{e}'"
    end

    # Public: Outputs stats string for cache
    def stats
      return "" unless Rails.cache.respond_to? :stats

      stats    = Rails.cache.stats
      values     = stats.select{|k,v| k =~ Regexp.new(host) }.values[0]
      mem_used = to_megabytes values['bytes']
      mem_max  = to_megabytes values['limit_maxbytes']
      return "#{mem_used} / #{mem_max} MB, #{stats.count - 1} peers"
    rescue => e
      raise ConnectionFailed, e
    end

    private

    # Private: Convert bytes to megabytes
    def to_megabytes(bytes)
      bytes.to_i / (1024 * 1024)
    end

    ConnectionFailed = Class.new(StandardError)
  end
end
