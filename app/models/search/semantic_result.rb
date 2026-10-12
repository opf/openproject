# frozen_string_literal: true

module Search
  class SemanticResult
    RESULT_LIMIT = 10
    MAX_SEMANTIC_DISTANCE = 0.5

    def self.for(query, user)
      binding = active_binding
      return WorkPackage.none unless binding&.locked?

      query_vector = embed(query, binding)
      return WorkPackage.none if query_vector.nil?

      closest_visible_work_packages(query_vector, user)
    end

    private_class_method def self.closest_visible_work_packages(vector, user)
      distance = "work_package_embeddings.embedding <=> '#{vector}'"

      WorkPackage
        .visible(user)
        .joins("INNER JOIN work_package_embeddings ON work_package_embeddings.work_package_id = work_packages.id")
        .where(Arel.sql("#{distance} < #{MAX_SEMANTIC_DISTANCE}"))
        .order(Arel.sql(distance))
        .limit(RESULT_LIMIT)
        .preload(:project, :status)
        .load
    end

    private_class_method def self.active_binding
      LlmConnection.active_connection
                   &.feature_bindings
                   &.find_by(feature_key: "semantic_search")
    end

    private_class_method def self.embed(query, binding)
      session = Llm::Session.for(binding.llm_connection)
      vectors = session.embed(query, model: binding.resolved_model_id, dimensions: binding.dimensions).vectors
      WorkPackageEmbedding.vector_literal(vectors) if vectors.present?
    rescue Llm::Errors::Error
      nil
    end
  end
end
