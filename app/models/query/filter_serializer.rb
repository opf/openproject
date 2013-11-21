module Query::FilterSerializer
  def self.load(serialized_filter_hash)
    return [] if serialized_filter_hash.nil?
    Query::WorkPackages::Filter.from_hash(YAML.load(serialized_filter_hash) || {})
  end

  def self.dump(filters)
    YAML.dump (filters || []).map(&:to_hash).reduce(:merge)
  end
end
