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
    class EmbedService
      def initialize(work_packages)
        @work_packages = Array(work_packages)
      end

      def call
        raise Llm::Errors::ConfigurationError, "binding not ready" unless binding_ready?

        result = session.embed(texts, model: binding.resolved_model_id, dimensions: binding.dimensions)

        store(result.vectors)
        lock_binding_on_first_write
      end

      private

      attr_reader :work_packages

      def binding
        @binding ||= LlmConnection.active_connection
                                  &.feature_bindings
                                  &.find_or_initialize_by(feature_key: "semantic_search")
      end

      def binding_ready?
        binding.present? && binding.resolved_model_id.present?
      end

      def session = Llm::Session.for(binding.llm_connection)

      def texts
        context_window = binding.llm_connection.models.find_by(external_id: binding.resolved_model_id)&.context_window

        work_packages.map { |wp| EmbeddableText.for(wp, context_window: context_window) }
      end

      def store(vectors)
        rows = work_packages.zip(vectors).map do |work_package, vector|
          { work_package_id: work_package.id, embedding: WorkPackageEmbedding.vector_literal(vector) }
        end

        WorkPackageEmbedding.upsert_all(rows, unique_by: :work_package_id)
      end

      def lock_binding_on_first_write
        return if binding.locked?

        binding.update!(locked_at: Time.current)
      end
    end
  end
end
