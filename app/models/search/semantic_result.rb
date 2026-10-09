# frozen_string_literal: true

module Search
  class SemanticResult
    CANDIDATES_LIMIT = 100
    SEMANTIC_DISTANCE = 0.5

    def self.available?
      active_binding&.locked? || false
    end

    # Work package ids ordered from most to least similar. Memoized per request:
    # the query filter and the similarity sort both ask for them.
    def self.ranked_ids(query)
      RequestStore.fetch([:semantic_search_ranked_ids, query]) { fetch_ranked_ids(query) }
    end

    private_class_method def self.fetch_ranked_ids(query)
      binding = active_binding
      return [] if query.blank? || !binding&.locked?

      vectors = embed(query, binding)
      return [] if vectors.blank?

      sanitized = sanitize_vector(vectors)
      WorkPackageEmbedding
        .for_model(binding.resolved_model_id)
        .where(Arel.sql("embedding <=> '#{sanitized}' < #{SEMANTIC_DISTANCE}"))
        .order(Arel.sql("embedding <=> '#{sanitized}'"))
        .limit(CANDIDATES_LIMIT)
        .pluck(:work_package_id)
    end

    private_class_method def self.active_binding
      LlmConnection.active_connection
                   &.feature_bindings
                   &.find_by(feature_key: "semantic_search")
    end

    private_class_method def self.embed(query, binding)
      session = Llm::Session.for(binding.llm_connection)
      session.embed(query, model: binding.resolved_model_id, dimensions: binding.dimensions).vectors
    rescue Llm::Errors::Error
      nil
    end

    # Formats a float array as a pgvector literal and escapes it for safe
    # inline use in an ORDER BY clause. Only numeric characters, commas, and
    # brackets are allowed -- no user input survives in the output.
    private_class_method def self.sanitize_vector(vectors)
      "[#{Array(vectors).map { |v| Float(v) }.join(',')}]"
    end
  end
end
