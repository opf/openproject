# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Llm
  module WorkPackages
    module SemanticSearch
      def self.available?
        return false unless runtime.ready?

        active_semantic_index&.searchable? || false
      end

      # Memoized per request: availability check and embedding share one resolution.
      def self.runtime
        RequestStore.fetch(:semantic_search_runtime) { Llm::Runtime.for(:semantic_search) }
      end

      QUERY_VECTOR_CACHE_TTL = 1.day

      # Memoized per request: the query filter and the similarity sort both need it.
      def self.query_vector(query)
        RequestStore.fetch([:semantic_search_query_vector, query]) { fetch_query_vector(query) }
      end

      # The query vector of an earlier embedding of the same query, never calling the
      # embedding API. Nil when the query has not been embedded recently.
      def self.cached_query_vector(query)
        RequestStore.fetch([:semantic_search_cached_query_vector, query]) do
          next if query.blank?
          next unless available?

          Rails.cache.read(query_vector_cache_key(query))
        end
      end

      # The index query embedding and result ranking run against.
      def self.active_semantic_index
        RequestStore.fetch(:semantic_search_active_index) { SemanticIndex.active }
      end

      private_class_method def self.fetch_query_vector(query)
        return if query.blank?
        return unless available?

        Rails.cache.fetch(query_vector_cache_key(query), expires_in: QUERY_VECTOR_CACHE_TTL, skip_nil: true) do
          embed(query)
        end
      end

      private_class_method def self.query_vector_cache_key(query)
        index = active_semantic_index
        ["llm/semantic_search/query_vector", index.id, index.model_id, index.embedding_vector_dimensions,
         Digest::SHA256.hexdigest(query)]
      end

      private_class_method def self.embed(query)
        vector = runtime.embed(query,
                               dimensions: active_semantic_index.embedding_vector_dimensions).vectors
        WorkPackageEmbedding.vector_literal(vector) if vector.present?
      rescue Llm::Errors::Error
        nil
      end
    end
  end
end
