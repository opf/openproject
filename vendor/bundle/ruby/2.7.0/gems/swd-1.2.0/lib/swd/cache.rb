module SWD
  class Cache
    def fetch(cache_key, options = {})
      yield
    end
  end
end