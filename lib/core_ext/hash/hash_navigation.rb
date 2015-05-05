module HashNavigation
  def fetch?(*keys)
    value = fetch_path keys, self

    if value
      value
    elsif block_given?
      yield
    else
      nil
    end
  end

  module_function

  def fetch_path(keys, hash, default = nil)
    if keys.size <= 1
      fetch_value keys.first, hash, default
    else
      head, *tail = keys

      fetch_path tail, fetch_hash(head, hash), default
    end
  end

  def fetch_hash(key, hash)
    ActiveSupport::HashWithIndifferentAccess.new fetch_value(key, hash)
  end

  def fetch_value(key, hash, default = nil)
    hash[key] || default
  end
end

Hash.include HashNavigation
