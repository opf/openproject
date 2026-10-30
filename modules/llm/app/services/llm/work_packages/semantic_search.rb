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
        return false unless Llm::Runtime.for(:semantic_search).ready?

        active_semantic_index&.ready? || false
      end

      # Memoized per request: the query filter and the similarity sort both need it.
      def self.query_vector(query)
        RequestStore.fetch([:semantic_search_query_vector, query]) { fetch_query_vector(query) }
      end

      # The index query embedding and result ranking run against.
      def self.active_semantic_index
        RequestStore.fetch(:semantic_search_active_index) { SemanticIndex.active }
      end

      private_class_method def self.fetch_query_vector(query)
        return if query.blank?
        return unless available?

        embed(query, active_semantic_index.embedding_vector_dimensions)
      end

      private_class_method def self.embed(query, dimensions)
        vector = Llm::Runtime.for(:semantic_search).embed(query, dimensions:).vectors
        WorkPackageEmbedding.vector_literal(vector) if vector.present?
      rescue Llm::Errors::Error
        nil
      end
    end
  end
end
