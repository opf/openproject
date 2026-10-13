# frozen_string_literal: true

module Search
  class SemanticResult
    MAX_SEMANTIC_DISTANCE = 0.5

    def self.available?
      active_binding&.locked? || false
    end

    # Memoized per request: the query filter and the similarity sort both need it.
    def self.query_vector(query)
      RequestStore.fetch([:semantic_search_query_vector, query]) { fetch_query_vector(query) }
    end

    def self.matching_work_package_ids_sql(vector)
      <<~SQL.squish
        SELECT work_package_id FROM work_package_embeddings
        WHERE embedding <=> '#{vector}' < #{MAX_SEMANTIC_DISTANCE}
      SQL
    end

    def self.distance_sql(vector)
      <<~SQL.squish
        (SELECT embedding <=> '#{vector}' FROM work_package_embeddings
         WHERE work_package_embeddings.work_package_id = #{WorkPackage.table_name}.id)
      SQL
    end

    private_class_method def self.fetch_query_vector(query)
      binding = active_binding
      return if query.blank? || !binding&.locked?

      embed(query, binding)
    end

    private_class_method def self.active_binding
      LlmConnection.active_connection
                   &.feature_bindings
                   &.find_by(feature_key: "semantic_search")
    end

    private_class_method def self.embed(query, binding)
      session = Llm::Session.for(binding.llm_connection)
      vector = session.embed(query, model: binding.resolved_model_id, dimensions: binding.dimensions).vectors
      WorkPackageEmbedding.vector_literal(vector) if vector.present?
    rescue Llm::Errors::Error
      nil
    end
  end
end
