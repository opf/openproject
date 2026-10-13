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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Llm
  module WorkPackages
    module SemanticSearch
      def self.available?
        return false unless OpenProject::FeatureDecisions.semantic_search_active?

        active_binding&.locked? || false
      end

      # Memoized per request: the query filter and the similarity sort both need it.
      def self.query_vector(query)
        RequestStore.fetch([:semantic_search_query_vector, query]) { fetch_query_vector(query) }
      end

      private_class_method def self.fetch_query_vector(query)
        return if query.blank? || !OpenProject::FeatureDecisions.semantic_search_active?

        binding = active_binding
        return unless binding&.locked?

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
end
