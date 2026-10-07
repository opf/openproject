# frozen_string_literal: true

module Search
  class SemanticResult
    CANDIDATES_LIMIT = 50
    RESULT_LIMIT = 10
    SEMANTIC_DISTANCE = 0.5

    def self.for(query, user)
      binding = active_binding
      return WorkPackage.none unless binding&.locked?

      vectors = embed(query, binding)
      return WorkPackage.none if vectors.blank?

      sanitized = sanitize_vector(vectors)
      candidates = WorkPackageEmbedding
        .for_model(binding.resolved_model_id)
        .where(Arel.sql("embedding <=> '#{sanitized}' < #{SEMANTIC_DISTANCE}"))
        .order(Arel.sql("embedding <=> '#{sanitized}'"))
        .limit(CANDIDATES_LIMIT)
        .pluck(:work_package_id)

      return WorkPackage.none if candidates.empty?

      WorkPackage
        .visible(user)
        .where(id: candidates)
        .includes(:project, :status)
        .order(Arel.sql("array_position(ARRAY[#{candidates.join(',')}]::int[], work_packages.id)"))
        .first(RESULT_LIMIT)
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
